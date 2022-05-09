# frozen_string_literal: true

Rails.application.routes.draw do
  root 'root#index'

  delete 'destroy', to: 'test#destroy'
end
