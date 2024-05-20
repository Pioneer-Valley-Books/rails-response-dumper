# frozen_string_literal: true

ResponseDumper.configure do |config|
  config.before_all do
    RootController.test_before_all_attribute = 'Test Before All'
  end

  config.after_all do
    RootController.test_before_all_attribute = nil
  end
end
