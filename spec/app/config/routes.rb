# frozen_string_literal: true

Rails.application.routes.draw do
  root 'root#index'

  resource :tests, only: [:destroy]
end
