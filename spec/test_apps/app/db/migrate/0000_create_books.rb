# frozen_string_literal: true

class CreateBooks < ActiveRecord::Migration[7.0]
  def change
    create_table 'books' do |t|
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
    end
  end
end
