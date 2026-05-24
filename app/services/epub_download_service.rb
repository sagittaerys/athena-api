class EpubDownloadService
  EPUB_STORAGE_PATH = Rails.root.join("storage/epubs")

  def initialize(library_item)
    @library_item = library_item
  end

  def fetch
    cached_path = cache_path
    return cached_path if File.exist?(cached_path)

    raise ArgumentError, "No EPUB URL available" unless @library_item.epub_url.present?

    download_epub(cached_path)
    cached_path
  end

  def clear_cache
    FileUtils.rm_f(cache_path)
  end

  private

  def cache_path
    user_dir = EPUB_STORAGE_PATH.join(@library_item.user_id.to_s)
    FileUtils.mkdir_p(user_dir)
    user_dir.join("#{@library_item.id}.epub").to_s
  end

  def download_epub(destination)
    response = HTTParty.get(@library_item.epub_url, timeout: 30)
    raise "Failed to download EPUB: #{response.code}" unless response.success?

    File.binwrite(destination, response.body)
  end
end
