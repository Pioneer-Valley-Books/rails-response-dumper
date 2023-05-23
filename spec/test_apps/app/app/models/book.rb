# frozen_string_literal: true

class Book < ApplicationRecord
  after_commit do
    puts 'Commit Book' if ENV['AFTER_COMMIT']
  end
end
