# frozen_string_literal: true

def tmpdir
  @tmpdir ||= Dir.mktmpdir
end

RSpec.configure do |config|
  config.before do
    tmpdir
  end

  config.after do
    FileUtils.remove_entry_secure(tmpdir)
  end
end
