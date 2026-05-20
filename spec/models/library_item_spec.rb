require 'rails_helper'

RSpec.describe LibraryItem, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    subject(:library_item) { build(:library_item) }

    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:source) }
    it { should validate_inclusion_of(:source).in_array(LibraryItem::SOURCES) }
  end

  describe "scopes" do
    let!(:gutenberg_item) { create(:library_item, source: "gutenberg") }
    let!(:imported_item)  { create(:library_item, source: "imported") }
    let!(:ebooks_item)    { create(:library_item, source: "standard_ebooks") }

    it "filters by source" do
      expect(LibraryItem.by_source("gutenberg")).to include(gutenberg_item)
    end

    it "returns imported items" do
      expect(LibraryItem.imported).to include(imported_item)
    end

    it "returns catalog items excluding imported" do
      expect(LibraryItem.from_catalog).not_to include(imported_item)
      expect(LibraryItem.from_catalog).to include(gutenberg_item)
    end

    it "orders by most recent" do
      expect(LibraryItem.recent.first).to eq(ebooks_item)
    end
  end
end
