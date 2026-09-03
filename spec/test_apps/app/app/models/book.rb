# frozen_string_literal: true

class Book < ApplicationRecord
  after_commit do
    # rubocop:disable-next RSpec/Output
    puts 'Commit Book' if ENV['AFTER_COMMIT']
  end
end
