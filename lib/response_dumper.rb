# frozen_string_literal: true

require 'rspec/mocks'
require_relative 'response_dumper_configure'

class ResponseDumper
  include ActionDispatch::Integration::Runner
  include ActiveSupport::Testing::TimeHelpers
  include RSpec::Mocks::ExampleMethods

  def self.define(name, &block)
    RailsResponseDumper::Defined.new(name, @config, &block)
  end

  def self.configure
    @config = ResponseDumperConfigure.new
    yield @config
  end

  # Delegates to `Rails.application`.
  def app
    Rails.application
  end

  def responses
    @responses ||= []
  end

  def mock_setup
    RSpec::Mocks.setup
  end

  def mock_teardown
    RSpec::Mocks.verify
  ensure
    RSpec::Mocks.teardown
  end

  %i[get post patch put head delete].each do |method|
    module_eval <<~RUBY, __FILE__, __LINE__ + 1
      def #{method}(...)
        result = super
        self.responses << [response, Time.zone.now]
        result
      end
    RUBY
  end

  # The list of methods is too long to be useful so shorten to just the class
  # name.
  def inspect
    "#<#{self.class.name}>"
  end
end
