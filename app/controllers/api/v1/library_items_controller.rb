module Api
  module V1
    class LibraryItemsController < ApplicationController
      def index
        library_items = current_user.library_items.recent
        render json: { library_items: serialize_library_items(library_items) }, status: :ok
      end

      def show
        library_item = current_user.library_items.find_by(id: params[:id])

        if library_item
          render json: { library_item: serialize_library_item(library_item) }, status: :ok
        else
          render json: { error: "Not found" }, status: :not_found
        end
      end

      def create
        existing = current_user.library_items.find_by(
          external_id: params[:external_id],
          source: params[:source]
        )

        if existing
          render json: { error: "Book already in your library" }, status: :unprocessable_entity
          return
        end

        library_item = current_user.library_items.build(library_item_params)

        if library_item.save
          ReadingProgress.create!(
            user: current_user,
            library_item: library_item,
            current_chapter: 0,
            position_seconds: 0.0,
            completed: false
          )

          render json: { library_item: serialize_library_item(library_item) }, status: :created
        else
          render json: { error: library_item.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def destroy
        library_item = current_user.library_items.find_by(id: params[:id])

        if library_item
          library_item.destroy
          render json: { message: "Book removed from library" }, status: :ok
        else
          render json: { error: "Not found" }, status: :not_found
        end
      end

      private

      def library_item_params
        params.permit(:external_id, :source, :title, :author, :cover_url, :epub_url)
      end

      def serialize_library_item(item)
        {
          id: item.id,
          external_id: item.external_id,
          source: item.source,
          title: item.title,
          author: item.author,
          cover_url: item.cover_url,
          epub_url: item.epub_url,
          created_at: item.created_at
        }
      end

      def serialize_library_items(items)
        items.map { |item| serialize_library_item(item) }
      end
    end
  end
end
