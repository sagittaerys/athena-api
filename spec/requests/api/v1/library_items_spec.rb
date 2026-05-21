require "rails_helper"

RSpec.describe "Api::V1::LibraryItems", type: :request do
  let!(:user) { create(:user) }
  let!(:access_token) { JwtService.generate_access_token(user.id) }
  let(:auth_headers) { { "Authorization" => "Bearer #{access_token}" } }

  let(:valid_params) do
    {
      external_id: "1342",
      source: "gutenberg",
      title: "Pride and Prejudice",
      author: "Jane Austen",
      cover_url: "https://example.com/cover.jpg",
      epub_url: "https://example.com/book.epub"
    }
  end

  describe "GET /api/v1/library_items" do
    let!(:library_item) { create(:library_item, user: user) }
    let!(:other_item) { create(:library_item) }

    it "returns 200 and user's library" do
      get "/api/v1/library_items", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json_response["library_items"]).to be_an(Array)
    end

    it "only returns current user's items" do
      get "/api/v1/library_items", headers: auth_headers

      ids = json_response["library_items"].map { |i| i["id"] }

      expect(ids).to include(library_item.id)
      expect(ids).not_to include(other_item.id)
    end

    it "returns 401 without token" do
      get "/api/v1/library_items"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/library_items" do
    before do
      create(:library_item, user: user, external_id: "9999")
    end

    it "returns 201 and creates library item" do
      expect do
        post "/api/v1/library_items",
             params: valid_params,
             headers: auth_headers
      end.to change(LibraryItem, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response["library_item"]["title"]).to eq("Pride and Prejudice")
    end

    it "creates reading progress automatically" do
      expect do
        post "/api/v1/library_items",
             params: valid_params,
             headers: auth_headers
      end.to change(ReadingProgress, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "returns 422 when book already in library" do
      create(
        :library_item,
        user: user,
        external_id: valid_params[:external_id],
        source: valid_params[:source]
      )

      post "/api/v1/library_items",
           params: valid_params,
           headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 401 without token" do
      post "/api/v1/library_items", params: valid_params

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/library_items/:id" do
    let!(:library_item) { create(:library_item, user: user) }
    let!(:other_item) { create(:library_item) }

    it "returns 200 and the item" do
      get "/api/v1/library_items/#{library_item.id}",
          headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json_response["library_item"]["id"]).to eq(library_item.id)
    end

    it "returns 404 for non-existent item" do
      get "/api/v1/library_items/999999",
          headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for another user's item" do
      get "/api/v1/library_items/#{other_item.id}",
          headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/library_items/:id" do
    let!(:library_item) { create(:library_item, user: user) }

    it "returns 200 and removes item" do
      expect do
        delete "/api/v1/library_items/#{library_item.id}",
               headers: auth_headers
      end.to change(LibraryItem, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for non-existent item" do
      delete "/api/v1/library_items/999999",
             headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for another user's item" do
      other_item = create(:library_item)

      delete "/api/v1/library_items/#{other_item.id}",
             headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
