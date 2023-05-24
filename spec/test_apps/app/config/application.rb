# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    config.load_defaults 7.0
    # Avoid non-deterministic headers
    config.middleware.delete ActionDispatch::RequestId
    config.middleware.delete Rack::Runtime
  end
end
