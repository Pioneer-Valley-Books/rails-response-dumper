# frozen_string_literal: true

require 'mime/types'
require_relative 'defined'

module RailsResponseDumper
  class Runner
    def run_dumps
      dumps_dir = Rails.root.join('dumps')
      FileUtils.rm_rf dumps_dir
      FileUtils.mkdir_p dumps_dir

      Dir[Rails.root.join('dumpers/**/*.rb')].each { |f| require f }

      RailsResponseDumper::Defined.dumpers.each do |defined|
        defined.blocks.each do |dump_block|
          defined.reset_models!

          dumper = defined.klass.new
          dumper.mock_setup
          begin
            ActiveRecord::Base.transaction do
              dumper.instance_eval(&dump_block.block)
              raise ActiveRecord::Rollback
            end
          ensure
            dumper.mock_teardown
          end

          klass_path = defined.name.underscore
          dumper_dir = "#{dumps_dir}/#{klass_path}/#{dump_block.name}"
          FileUtils.mkdir_p dumper_dir

          dumper.responses.each_with_index do |response, index|
            unless response.status == dump_block.expected_status_code
              raise <<~ERROR.squish
                #{defined.name}.#{dump_block.name} has unexpected status
                code #{response.status} #{response.status_message}
                (expected #{dump_block.expected_status_code})
              ERROR
            end

            mime = response.content_type.split(/ *; */).first
            extension = MIME::Types[mime].first.preferred_extension
            File.write("#{dumper_dir}/#{index}.#{extension}", response.body)
          end
        end
      end
    end
  end
end
