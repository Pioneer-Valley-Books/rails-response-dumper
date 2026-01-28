# frozen_string_literal: true

class Book < ApplicationRecord
  after_commit do
    # rubocop:disable RSpec/Output
    puts 'Commit Book' if ENV['AFTER_COMMIT']
    # rubocop:enable RSpec/Output
  end
end
