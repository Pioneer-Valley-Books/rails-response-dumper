# frozen_string_literal: true

ResponseDumper.configure do |config|
  config.after_all do
    FileUtils.touch("#{ENV.fetch('TMPDIR')}/#{ENV.fetch('AFTER_ALL_FILENAME')}")
  end
end
