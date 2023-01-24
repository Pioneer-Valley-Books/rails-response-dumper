# frozen_string_literal: true

require 'optparse'

module RailsResponseDumper
  def self.parse_options!
    options = {}

    OptionParser.new do |opts|
      opts.on('--fail-fast', 'Abort the run after first failure.') do |v|
        options[:fail_fast] = v
      end
    end.parse!

    options.freeze
  end
end
