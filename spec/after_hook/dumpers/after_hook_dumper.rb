# frozen_string_literal: true

ResponseDumper.define 'after_hook' do
  after do
    FileUtils.touch("#{ENV.fetch('TMPDIR')}/#{ENV.fetch('FILENAME')}")
  end

  dump 'after_hook' do
    raise 'after hook error'
  end
end
