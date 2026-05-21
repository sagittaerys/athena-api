class BookSearchService
  GUTENDEX_BASE = "https://gutendex.com/books"
  OPEN_LIBRARY_BASE = "https://openlibrary.org/search.json"

  def self.search(query:)
    results = search_gutendex(query: query)
    results = search_open_library(query: query) if results.empty?
    results
  rescue StandardError
    search_open_library(query: query)
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

  def self.search_gutendex(query:)
    url = "#{GUTENDEX_BASE}?search=#{URI.encode_www_form_component(query)}&languages=en&copyright=false"
    response = HTTParty.get(url, timeout: 10)
    return [] unless response.success?

    data = response.parsed_response
    data["results"].map { |book| normalize_gutendex(book) }
  rescue StandardError
    []
  end

  def self.search_open_library(query:)
    url = "#{OPEN_LIBRARY_BASE}?q=#{URI.encode_www_form_component(query)}&limit=20"
    response = HTTParty.get(url, timeout: 10)
    return [] unless response.success?

    data = response.parsed_response
    data["docs"].map { |book| normalize_open_library(book) }
  rescue StandardError
    []
  end

  def self.find_gutendex_book(external_id)
    response = HTTParty.get("#{GUTENDEX_BASE}/#{external_id}", timeout: 10)
    return nil unless response.success?
    normalize_gutendex(response.parsed_response)
  rescue StandardError
    nil
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
    author = book["authors"]&.first&.dig("name") || "Unknown"
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
