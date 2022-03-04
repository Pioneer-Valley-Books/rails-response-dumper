# frozen_string_literal: true

module RailsResponseDumper
  class Runner
    def run_dumps
      dumps_dir = Rails.root.join('dumps')
      FileUtils.rm_rf dumps_dir
      FileUtils.mkdir_p dumps_dir

      Dir[Rails.root.join('dumpers/**/*.rb')].each { |f| require f }

      ResponseDumper.dumpers.each do |klass|
        klass.instance_methods.each do |method|
          next unless method.start_with?('dump_')

          klass.reset_models!

          dumper = klass.new
          dumper.mock_setup
          begin
            ActiveRecord::Base.transaction do
              dumper.expect_status_code!(:ok)
              dumper.send(method)
              raise ActiveRecord::Rollback
            end
          ensure
            dumper.mock_teardown
          end

          klass_path = klass.name.underscore
          dumper_dir = "#{dumps_dir}/#{klass_path}/#{method}"
          FileUtils.mkdir_p dumper_dir

          dumper.responses.each_with_index do |response, index|
            unless response.status == dumper.expected_status_code
              raise <<~ERROR.squish
                #{dumper.class.name}\##{method} has unexpected status
                code #{response.status} #{response.status_message}
                (expected #{dumper.expected_status_code})
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
