# frozen_string_literal: true

class BooksController < ApplicationController
  def create
    Book.create!
  end
end
