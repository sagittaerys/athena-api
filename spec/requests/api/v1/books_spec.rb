require "rails_helper"

RSpec.describe "Api::V1::Books", type: :request do
  let!(:user) { create(:user) }
  let!(:access_token) { JwtService.generate_access_token(user.id) }
  let(:auth_headers) { { "Authorization" => "Bearer #{access_token}" } }

  describe "GET /api/v1/books/genres" do
    it "returns list of genres" do
      get "/api/v1/books/genres", headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(json_response["genres"]).to include("Romance", "Fiction", "Adventure")
    end

    it "returns 401 without token" do
      get "/api/v1/books/genres"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/books" do
    before do
      allow(BookSearchService).to receive(:search).and_return([
        {
          external_id: "1342",
          source: "gutenberg",
          title: "Pride and Prejudice",
          author: "Jane Austen",
          cover_url: "https://example.com/cover.jpg",
          epub_url: "https://example.com/book.epub"
        }
      ])
    end

    it "returns books" do
      get "/api/v1/books", headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(json_response["books"]).to be_an(Array)
    end

    it "passes query to search service" do
      expect(BookSearchService).to receive(:search).with(
        query: "austen",
        genre: nil,
        page: 1
      ).and_return([])

      get "/api/v1/books", params: { query: "austen" }, headers: auth_headers
    end

    it "returns 401 without token" do
      get "/api/v1/books"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/books/:id" do
    before do
      allow(BookSearchService).to receive(:find_book).and_return({
        external_id: "1342",
        source: "gutenberg",
        title: "Pride and Prejudice",
        author: "Jane Austen",
        cover_url: "https://example.com/cover.jpg",
        epub_url: "https://example.com/book.epub"
      })
    end

    it "returns a book" do
      get "/api/v1/books/1342",
          params: { source: "gutenberg" },
          headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(json_response["book"]["title"]).to eq("Pride and Prejudice")
    end

    it "returns 404 when book not found" do
      allow(BookSearchService).to receive(:find_book).and_return(nil)
      get "/api/v1/books/99999",
          params: { source: "gutenberg" },
          headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
