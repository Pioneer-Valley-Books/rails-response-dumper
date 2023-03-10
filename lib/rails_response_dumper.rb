# frozen_string_literal: true

require_relative 'rails_response_dumper/option_parser'
require_relative 'rails_response_dumper/runner'
require_relative 'response_dumper'

module RailsResponseDumper
  def self.merge_options(options)
    current_runner = Thread.current[:current_rails_response_runner]
    current_runner.merge_options(options)
  end
end
