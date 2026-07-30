# athena-api

> The Rails API backend for Athena — a voice-cloning EPUB reading app.

This repository contains the Rails 8 API that powers Athena. It handles user authentication, book discovery across multiple free APIs (Gutenberg and Open Library), personal library management, EPUB parsing, and orchestrates communication with the TTS server for audio generation.

---

## What this service does

- Authenticates users with JWT access and refresh tokens
- Proxies and normalises book search results from Project Gutenberg and Open Library
- Manages each user's personal library and reading progress
- Downloads, caches, and parses EPUB files into chapter chunks ready for TTS synthesis
- Communicates internally with the athena-tts service for voice synthesis
- Rate limits auth endpoints to prevent brute force attacks

---

## Related repositories

| Repository | Description |
|---|---|
| [athena-mobile](https://github.com/sagittaerys/athena-mobile) | React Native mobile app |
| [athena-tts](https://github.com/sagittaerys/athena-tts) | Python FastAPI TTS server |

---

## Tech stack

- **Ruby 3.3.11**
- **Rails 8.1.3** (API mode)
- **PostgreSQL 16**
- **Solid Queue** — background job processing (built into Rails 8)
- **HTTParty** — external API calls (Gutendex, Open Library)
- **Nokogiri** — HTML/XML parsing for EPUB extraction
- **rubyzip** — EPUB unpacking
- **JWT** — access and refresh token generation
- **bcrypt** — password hashing via has_secure_password
- **rack-attack** — rate limiting on auth endpoints
- **rack-cors** — cross-origin request handling

---

## Prerequisites

- Ruby 3.3.11 (via rbenv recommended)
- PostgreSQL 16
- Bundler

---

## Local setup

```bash
# clone the repo
git clone https://github.com/sagittaerys/athena-api
cd athena-api

# install gems
bundle install

# set up environment variables
cp .env.example .env
# fill in your values (see Environment variables section below)

# create and migrate the database
bin/rails db:create db:migrate

# load solid queue schema
bin/rails runner "load Rails.root.join('db/queue_schema.rb')"

# start the rails server
bin/rails server

# in a separate terminal — start the job worker
bin/rails solid_queue:start
```

The API will be available at `http://localhost:3000`.

---

## Environment variables

Copy `.env.example` to `.env` and fill in:

```bash
# Database
DB_USERNAME=your_postgresql_username
DB_PASSWORD=your_postgresql_password
DB_HOST=localhost
DB_PORT=5432

# Rails
RAILS_ENV=development
ALLOWED_ORIGINS=http://localhost:8081
SECRET_KEY_BASE=your_secret_key_base

# TTS Server
TTS_SERVER_URL=http://localhost:8000
TTS_SECRET_KEY=your_shared_secret_with_tts_server
```

Generate a secret key base with:

```bash
bin/rails secret
```

---

## Running tests

```bash
bundle exec rspec
```

The test suite covers models, services, jobs, and request specs across all endpoints.

---

## Ota

This repo also ships an [`ota.yaml`](./ota.yaml) contract for deterministic setup, task execution,
CI/runtime proofing, and the production image build. Install Ota from the
[official installation guide](https://ota.run/docs/install), then inspect the contract-owned
surface before choosing a lane.

```bash
# validate the contract and inspect local readiness
ota validate .
ota doctor

# list human and agent-safe task usage, modes, and dry-run commands
ota tasks --use
ota tasks --safe --use

# prepare the native Rails runtime with PostgreSQL
ota up --workflow app --mode native

# start the Rails API
ota run dev --mode native

# in a separate terminal, start the job worker
ota run worker --mode native

# run the bounded native verification lane
ota up --workflow verify-static --mode native

# run the same bounded verification lane in Ota's Ruby container context
ota up --workflow verify-static --mode container

# build the documented production image through the typed Ota action
ota up --workflow image
```

---

## Database schema

```
users
  — email, username, password_digest

voice_profiles
  — belongs to user
  — kokoro_profile_id, sample_url, status (pending | ready | failed)

library_items
  — belongs to user
  — external_id, source, title, author, cover_url, epub_url

reading_progress
  — belongs to user and library_item
  — current_chapter, position_seconds, completed

audio_chunks
  — belongs to user and library_item
  — chapter_index, chunk_index, text, audio_url, status

refresh_tokens
  — belongs to user
  — token_digest, jti, expires_at, revoked
```

---

## API reference

All endpoints except `/api/v1/auth/register` and `/api/v1/auth/login` require authentication:

```
Authorization: Bearer <access_token>
```

### Auth

```
POST   /api/v1/auth/register     — create account
POST   /api/v1/auth/login        — login, receive tokens
POST   /api/v1/auth/refresh      — rotate refresh token
DELETE /api/v1/auth/logout       — revoke refresh token
```

### Books

```
GET /api/v1/books                — search books (query, genre, page params)
GET /api/v1/books/genres         — list available genres
GET /api/v1/books/:id            — get book details (source param required)
```

### Library

```
GET    /api/v1/library_items                         — get user's library
POST   /api/v1/library_items                         — add book to library
GET    /api/v1/library_items/:id                     — get one library item
DELETE /api/v1/library_items/:id                     — remove from library
POST   /api/v1/library_items/:id/parse_epub          — parse EPUB into chapters and chunks
```

### Voice Profiles

```
POST   /api/v1/voice_profiles          — upload voice sample, create profile
GET    /api/v1/voice_profiles/:id      — get voice profile status
DELETE /api/v1/voice_profiles/:id      — delete voice profile
```

### Audio

```
POST /api/v1/library_items/:id/audio_chunks                    — request audio generation (async)
GET  /api/v1/library_items/:id/audio_chunks/:id                — poll chunk status
GET  /api/v1/library_items/:id/audio_chunks/:id/stream         — stream audio file
```

---

## Authentication design

Access tokens expire after **15 minutes**. Refresh tokens expire after **30 days** and are single-use while they are rotated on every refresh request. On logout, the refresh token is revoked immediately. Refresh token digests are hashed with SHA256 before storage — raw tokens never touch the database.

Rate limits on auth endpoints:
- Register: 5 requests per IP per hour
- Login: 10 requests per IP per hour
- Refresh: 30 requests per IP per hour

---

## Book sources

| Source | API | Notes |
|---|---|---|
| Project Gutenberg | Gutendex (gutendex.com) | Primary — no API key required |
| Open Library | openlibrary.org/search.json | Fallback — no API key required |

Gutendex is hit first. If it returns empty results, the request falls back to Open Library automatically. Both sources return a normalised response shape so the mobile app never needs to know which API was used.

---

## EPUB handling

When a user triggers playback for a book:

1. The EPUB is downloaded from the source URL and cached in `storage/epubs/<user_id>/<library_item_id>.epub`
2. `EpubParserService` unpacks the ZIP, reads the OPF manifest for chapter order, extracts text from each HTML chapter, and splits it into ~500 character chunks
3. Chunks are returned to the mobile app, which requests audio synthesis from Rails for each chunk
4. Rails enqueues an `AudioSynthesisJob` via Solid Queue — returns immediately with `status: pending`
5. The job calls the athena-tts service, receives WAV audio, saves it to `storage/audio/`
6. The mobile app polls until `status: ready`, then streams audio via the stream endpoint

---

## Contributing

1. Fork the repository
2. Create a feature branch — `git checkout -b feat/your-feature`
3. Write tests for your changes
4. Ensure all tests pass — `bundle exec rspec`
5. Submit a pull request

Please follow the existing code style. Rubocop runs on every PR via GitHub Actions.

---

## License

Apache 2.0
