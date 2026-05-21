module Api
  module V1
    class BooksController < ApplicationController
      def index
        books = BookSearchService.search(
          query: params[:query],
          genre: genre_param,
          page: params.fetch(:page, 1).to_i
        )

        render json: { books: books }, status: :ok
      end

      def show
        book = BookSearchService.find_book(
          source: params[:source],
          external_id: params[:id]
        )

        if book
          render json: { book: book }, status: :ok
        else
          render json: { error: "Book not found" }, status: :not_found
        end
      end

      def genres
        render json: { genres: BookSearchService::GENRES.keys }, status: :ok
      end

      private

      def genre_param
        return nil unless params[:genre].present?
        BookSearchService::GENRES[params[:genre]]
      end
    end
  end
end
