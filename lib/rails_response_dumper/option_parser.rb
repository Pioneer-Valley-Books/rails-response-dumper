# frozen_string_literal: true

require 'optparse'

module RailsResponseDumper
  def self.parse_options!
    options = {}

    OptionParser.new do |opts|
      options['dumps-dir'] = Rails.root.join('dumps')

      opts.on('--dumps-dir PATH', 'Output dumps to this directory.') do |v|
        options['dumps-dir'] = v
      end

      opts.on('--fail-fast', 'Abort the run after first failure.') do |v|
        options[:fail_fast] = v
      end

      opts.on('--verbose', 'Output dumper and dump block names.') do |v|
        options[:verbose] = v
      end

      opts.on('--order TYPE', 'Run dumps by the specified order type.') do |v|
        options[:order] = v
      end

      opts.on('--exclude-response-headers', 'Do not output response headers.') do |v|
        options[:exclude_response_headers] = v
      end
    end.parse!

    options.freeze
  end
end
