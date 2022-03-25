# frozen_string_literal: true

require 'spec_helper'

APP_DIR = File.expand_path('app', __dir__)

RSpec.describe 'CLI' do
  it 'renders reproducible dumps' do
    system('bundle', 'exec', 'rails-response-dumper', chdir: APP_DIR, exception: true)
    expect(File.join(APP_DIR, 'dumps')).to match_snapshots
  end
end
