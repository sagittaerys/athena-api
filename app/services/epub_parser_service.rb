require "zip"
require "nokogiri"

class EpubParserService
  class EpubParseError < StandardError; end

  def initialize(epub_path)
    @epub_path = epub_path
  end

  def parse
    chapters = []

    Zip::File.open(@epub_path) do |zip|
      opf_path = find_opf_path(zip)
      raise EpubParseError, "Could not find content.opf" unless opf_path

      opf_content = zip.read(opf_path)
      opf_dir = File.dirname(opf_path)

      chapter_files = extract_chapter_files(opf_content, opf_dir)

      chapter_files.each_with_index do |file_path, index|
        content = zip.read(file_path) rescue next
        text = extract_text(content)
        next if text.strip.empty?

        chapters << {
          chapter_index: index,
          title: "Chapter #{index + 1}",
          chunks: split_into_chunks(text)
        }
      end
    end

    chapters
  rescue Zip::Error => e
    raise EpubParseError, "Invalid EPUB file: #{e.message}"
  end

  private

  def find_opf_path(zip)
    container = zip.read("META-INF/container.xml") rescue nil
    return nil unless container

    doc = Nokogiri::XML(container)
    rootfile = doc.at_css("rootfile")
    rootfile&.attr("full-path")
  end

  def extract_chapter_files(opf_content, opf_dir)
    doc = Nokogiri::XML(opf_content)

    doc.remove_namespaces!

    spine_idrefs = doc.css("spine itemref").map { |ref| ref.attr("idref") }

    manifest_items = {}
    doc.css("manifest item").each do |item|
      manifest_items[item.attr("id")] = item.attr("href")
    end

    spine_idrefs.map do |idref|
      href = manifest_items[idref]
      next unless href
      opf_dir == "." ? href : "#{opf_dir}/#{href}"
    end.compact
  end

  def extract_text(html_content)
    doc = Nokogiri::HTML(html_content)
    doc.css("script, style, nav").remove

    doc.css("a").each do |link|
      link.replace(link.text)
    end

    doc.css("p, h1, h2, h3, h4, h5, h6").map do |node|
      content = node.text.strip
      content.empty? ? nil : content
    end.compact.uniq.join("\n\n")
  end

  def split_into_chunks(text, max_chars: 500)
    paragraphs = text.split("\n\n").map(&:strip).reject(&:empty?)

    chunks = []
    current_chunk = ""
    chunk_index = 0

    paragraphs.each do |paragraph|
      if (current_chunk + paragraph).length > max_chars && !current_chunk.empty?
        chunks << { chunk_index: chunk_index, text: current_chunk.strip }
        chunk_index += 1
        current_chunk = paragraph
      else
        current_chunk += (current_chunk.empty? ? "" : "\n\n") + paragraph
      end
    end

    chunks << { chunk_index: chunk_index, text: current_chunk.strip } unless current_chunk.empty?
    chunks
  end
end
