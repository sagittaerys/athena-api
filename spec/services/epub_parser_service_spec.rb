require "rails_helper"
require "zip"

RSpec.describe EpubParserService do
  let(:epub_path) { Rails.root.join("spec/fixtures/files/test.epub").to_s }

  before(:all) do
    FileUtils.mkdir_p(Rails.root.join("spec/fixtures/files"))
    path = Rails.root.join("spec/fixtures/files/test.epub").to_s

    Zip::OutputStream.open(path) do |zip|
      zip.put_next_entry("mimetype")
      zip.write("application/epub+zip")

      zip.put_next_entry("META-INF/container.xml")
      zip.write(<<~XML)
        <?xml version="1.0"?>
        <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
          <rootfiles>
            <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
          </rootfiles>
        </container>
      XML

      zip.put_next_entry("OEBPS/content.opf")
      zip.write(<<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <package xmlns="http://www.idpf.org/2007/opf" version="2.0">
          <metadata/>
          <manifest>
            <item id="chapter1" href="chapter1.html" media-type="application/xhtml+xml"/>
          </manifest>
          <spine>
            <itemref idref="chapter1"/>
          </spine>
        </package>
      XML

      zip.put_next_entry("OEBPS/chapter1.html")
      zip.write(<<~HTML)
        <?xml version="1.0" encoding="utf-8"?>
        <html>
          <body>
            <p>It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.</p>
            <p>However little known the feelings or views of such a man may be on his first entering a neighbourhood, this truth is so well fixed in the minds of the surrounding families, that he is considered as the rightful property of some one or other of their daughters.</p>
          </body>
        </html>
      HTML
    end
  end

  after(:all) do
    FileUtils.rm_f(Rails.root.join("spec/fixtures/files/test.epub"))
  end

  describe "#parse" do
    it "returns an array of chapters" do
      parser = EpubParserService.new(epub_path)
      result = parser.parse
      expect(result).to be_an(Array)
      expect(result.length).to be > 0
    end

    it "each chapter has required keys" do
      parser = EpubParserService.new(epub_path)
      chapter = parser.parse.first
      expect(chapter).to include(:chapter_index, :title, :chunks)
    end

    it "each chunk has required keys" do
      parser = EpubParserService.new(epub_path)
      chunk = parser.parse.first[:chunks].first
      expect(chunk).to include(:chunk_index, :text)
    end

    it "extracts text from HTML chapters" do
      parser = EpubParserService.new(epub_path)
      chapters = parser.parse
      text = chapters.first[:chunks].map { |c| c[:text] }.join(" ")
      expect(text).to include("It is a truth universally acknowledged")
    end

    it "raises EpubParseError for invalid file" do
      parser = EpubParserService.new("/tmp/not_an_epub.epub")
      expect { parser.parse }.to raise_error(EpubParserService::EpubParseError)
    end
  end
end
