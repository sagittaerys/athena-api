class BookSearchService
  GUTENDEX_BASE = "https://gutendex.com/books"
  OPEN_LIBRARY_BASE = "https://openlibrary.org/search.json"

  def self.search(query: nil, page: 1, genre: nil)
    results = search_gutendex(query: query, page: page, genre: genre)
    results = search_open_library(query: query, page: page) if results.empty?
    results
  rescue StandardError
    search_open_library(query: query, page: page)
  end

  def self.find_book(source:, external_id:)
    case source
    when "gutenberg"
      find_gutendex_book(external_id)
    when "open_library"
      find_open_library_book(external_id)
    else
      nil
    end
  end

  private

  def self.search_gutendex(query:, page: 1, genre: nil)
    params = {
      languages: "en",
      copyright: false,
      page: page
    }
    params[:search] = query if query.present?
    params[:topic] = genre if genre.present?

    url = "#{GUTENDEX_BASE}?#{params.to_query}"
    response = HTTParty.get(url, timeout: 10)
    return [] unless response.success?

    data = response.parsed_response
    data["results"].map { |book| normalize_gutendex(book) }
  rescue StandardError => e
    Rails.logger.error "Gutendex search failed: #{e.message}"
    []
  end

  def self.search_open_library(query:, page: 1)
    params = {
      limit: 20,
      page: page
    }
    params[:q] = query if query.present?

    url = "#{OPEN_LIBRARY_BASE}?#{params.to_query}"
    response = HTTParty.get(url, timeout: 10)
    return [] unless response.success?

    data = response.parsed_response
    data["docs"].map { |book| normalize_open_library(book) }
  rescue StandardError => e
    Rails.logger.error "Open Library search failed: #{e.message}"
    []
  end

  def self.find_gutendex_book(external_id)
    response = HTTParty.get("#{GUTENDEX_BASE}/#{external_id}", timeout: 10)
    return nil unless response.success?
    normalize_gutendex(response.parsed_response)
  rescue StandardError
    nil
  end

  def self.format_author(name)
    return "Unknown" unless name
    parts = name.split(", ")
    parts.length == 2 ? "#{parts[1].split('(').first.strip} #{parts[0]}" : name
  end

  def self.find_open_library_book(external_id)
    response = HTTParty.get(
      "https://openlibrary.org/works/#{external_id}.json",
      timeout: 10
    )
    return nil unless response.success?
    normalize_open_library(response.parsed_response)
  rescue StandardError
    nil
  end

  def self.normalize_gutendex(book)
    author = format_author(book["authors"]&.first&.dig("name"))
    cover = book["formats"]&.dig("image/jpeg")
    epub = book["formats"]&.dig("application/epub+zip")

    {
      external_id: book["id"].to_s,
      source: "gutenberg",
      title: book["title"],
      author: author,
      cover_url: cover,
      epub_url: epub
    }
  end

  def self.normalize_open_library(book)
    key = book["key"]&.split("/")&.last

    {
      external_id: key,
      source: "open_library",
      title: book["title"],
      author: book["author_name"]&.first || "Unknown",
      cover_url: book["cover_i"] ? "https://covers.openlibrary.org/b/id/#{book["cover_i"]}-L.jpg" : nil,
      epub_url: nil
    }
  end
end
