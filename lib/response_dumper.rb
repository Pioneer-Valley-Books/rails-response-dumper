# frozen_string_literal: true

require "#{Dir.pwd}/config/environment"

class ResponseDumper
  include ActionDispatch::Integration::Runner
  include ActiveSupport::Testing::TimeHelpers
  include RSpec::Mocks::ExampleMethods

  attr_reader :expected_status_code

  def self.inherited(subclass)
    super
    dumpers << subclass
  end

  def self.dumpers
    @dumpers ||= []
  end

  def self.reset_models(*models)
    @reset_models ||= []
    @reset_models += models
  end

  def self.reset_models!
    reset_models.each do |model|
      model.connection.exec_query "TRUNCATE #{model.quoted_table_name} RESTART IDENTITY CASCADE"
    end
  end

  # Delegates to `Rails.application`.
  def app
    Rails.application
  end

  def expect_status_code!(status_code)
    @expected_status_code = Rack::Utils::SYMBOL_TO_STATUS_CODE[status_code]
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
        self.responses << response
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
