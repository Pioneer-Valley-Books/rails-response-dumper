# frozen_string_literal: true

Rails.application.routes.draw do
  root 'root#index'

  resource :books, only: %i[create]
  resource :tests, only: %i[create destroy]
end
