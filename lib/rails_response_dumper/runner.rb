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
      dumps_dir = Rails.root.join('dumps')
      FileUtils.rm_rf dumps_dir
      FileUtils.mkdir_p dumps_dir

      Dir[Rails.root.join('dumpers/**/*.rb')].each { |f| require f }

      errors = []

      dumper_blocks = RailsResponseDumper::Defined.dumpers.flat_map do |defined|
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

      catch :fail_fast do
        dumper_blocks.each do |(defined, dump_block)|
          name = "#{defined.name}.#{dump_block.name}"

          print "#{name} " if options[:verbose]

          defined.reset_models!
          dumper = defined.klass.new
          dumper.mock_setup
          begin
            rollback_after do
              dumper.instance_eval(&defined.before_block) if defined.before_block
              begin
                dumper.instance_eval(&dump_block.block)
              ensure
                dumper.instance_eval(&defined.after_block) if defined.after_block
              end
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

          dumper.responses.each_with_index do |response, index|
            unless response.status == dump_block.expected_status_codes[index]
              raise <<~ERROR.squish
                unexpected status code #{response.status} #{response.status_message}
                (expected #{dump_block.expected_status_codes[index]})
              ERROR
            end

            request = response.request

            response_headers = options[:exclude_response_headers] ? {} : response.headers

            dump = {
              request: {
                method: request.method,
                url: request.url,
                body: request.body.string
              },
              response: {
                status: response.status,
                status_text: response.status_message,
                headers: response_headers,
                body: response.body
              }
            }
            File.write("#{dumper_dir}/#{index}.json", JSON.pretty_generate(dump))
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
      return if errors.blank?

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

      exit(false)
    end

    private

    def rollback_after
      if defined?(ActiveRecord::Base)
        ActiveRecord::Base.transaction do
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
