# frozen_string_literal: true

require_relative 'defined'
require_relative 'colorize'

module RailsResponseDumper
  class Runner
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run_dumps
      dumps_dir = options['dumps-dir']

      if options[:filenames].present?
        globs = options[:filenames]
      else
        globs = ['dumpers/**/*_dumper.rb']
        FileUtils.rm_rf dumps_dir
      end

      FileUtils.mkdir_p dumps_dir

      globs.each do |glob|
        Dir[Rails.root.join(glob)].each { |f| require f }
      end

      errors = []

      dumper_blocks = RailsResponseDumper::Defined.dumpers.flat_map do |defined|
        if options[:filenames].present?
          # clear previous dumps for that file in case removed from updated dump file
          FileUtils.rm_rf "#{dumps_dir}/#{defined.name.underscore}/"
        end

        defined.blocks.map do |dump_block|
          [defined, dump_block]
        end
      end

      if options[:order].present?
        seed = if options[:order] == 'random'
                 Random.new_seed
               else
                 Integer(options[:order])
               end

        puts "Randomized with seed #{seed}"

        random = Random.new(seed)
        dumper_blocks.shuffle!(random: random)
      end

      profile = {}

      catch :fail_fast do
        dumper_blocks.each do |(defined, dump_block)|
          name = "#{defined.name}.#{dump_block.name}"

          print "#{name} " if options[:verbose]

          defined.reset_models!
          dumper = defined.klass.new
          dumper.mock_setup
          begin
            rollback_after do
              t0 = Time.now
              dumper.instance_eval(&defined.before_block) if defined.before_block
              begin
                dumper.instance_eval(&dump_block.block)
              ensure
                dumper.instance_eval(&defined.after_block) if defined.after_block
              end
              profile[name] = Time.now - t0
            end
          ensure
            dumper.mock_teardown
          end

          unless dumper.responses.count == dump_block.expected_status_codes.count
            raise <<~ERROR.squish
              #{dumper.responses.count} responses
              (expected #{dump_block.expected_status_codes.count})
            ERROR
          end

          klass_path = defined.name.underscore
          dumper_dir = "#{dumps_dir}/#{klass_path}/#{dump_block.name}"
          FileUtils.mkdir_p dumper_dir

          dumper.responses.each_with_index do |(response, timestamp), index|
            unless response.status == dump_block.expected_status_codes[index]
              raise <<~ERROR.squish
                unexpected status code #{response.status} #{response.status_message}
                (expected #{dump_block.expected_status_codes[index]})
              ERROR
            end

            request = response.request

            dump = {
              request: {
                url: request.url,
                env: request.headers.to_h
              },
              response: {
                status: response.status,
                statusText: response.status_message,
                headers: response.headers
              }
            }

            # request.headers includes nonstandard internal data, some of which also lacks default deterministic
            # serialization. Here we only want CGI standard and HTTP variables.
            dump[:request][:env].filter! do |key|
              key.in?(ActionDispatch::Http::Headers::CGI_VARIABLES) || key =~ /\AHTTP_/
            end

            dump[:response].delete(:headers) if options[:exclude_response_headers]

            dump[:timestamp] = timestamp.iso8601 unless options[:exclude_timestamp]

            File.write("#{dumper_dir}/#{index}.json", JSON.pretty_generate(dump))
            File.write("#{dumper_dir}/#{index}.request_body", request.body.string, mode: 'wb')
            File.write("#{dumper_dir}/#{index}.response_body", response.body, mode: 'wb')
          end

          RailsResponseDumper.print_color('.', :green)
          print("\n") if options[:verbose]
        rescue StandardError => e
          errors << {
            dumper_location: dump_block.block.source_location.join(':'),
            name: name,
            exception: e
          }

          RailsResponseDumper.print_color('F', :red)
          print("\n") if options[:verbose]

          throw :fail_fast if options[:fail_fast]
        end
      end

      puts

      unless errors.blank?
        puts

        errors.each do |error|
          RailsResponseDumper.print_color(
            "#{error[:dumper_location]} #{error[:name]} received #{error[:exception]}\n",
            :red
          )
          error[:exception].full_message(highlight: RailsResponseDumper::COLORIZE).lines do |line|
            RailsResponseDumper.print_color(line, :cyan)
          end
          puts
        end
      end

      if options.include?(:profile)
        puts

        # Sort in descending order to obtain the 10 slowest dumps.
        timings = profile.to_a.sort_by { |(_key, value)| -value }
        timings.first(10).each do |(dump, time)|
          formatted_time = format('%.2f', time)
          puts "#{dump} #{formatted_time} s"
        end

        puts
      end

      exit(errors.blank?)
    end

    private

    def rollback_after
      if defined?(ActiveRecord::Base)
        ActiveRecord::Base.transaction(joinable: false) do
          yield
          raise ActiveRecord::Rollback
        end
      else
        # ActiveRecord is not installed.
        yield
      end
    end
  end
end
