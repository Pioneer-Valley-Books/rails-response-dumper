# frozen_string_literal: true

require 'open3'
require 'spec_helper'

APP_DIR = File.expand_path('app', __dir__)
AFTER_HOOK_APP_DIR = File.expand_path('after_hook', __dir__)

RSpec.describe 'CLI' do
  it 'renders reproducible dumps' do
    system('bundle', 'exec', 'rails-response-dumper', chdir: APP_DIR, exception: true)
    expect(File.join(APP_DIR, 'dumps')).to match_snapshots
  end

  it 'runs after hook when an exception is raised' do
    env = { 'TMPDIR' => tmpdir, 'FILENAME' => 'test.out' }
    cmd = %w[bundle exec rails-response-dumper]
    _stdout, stderr, status = Open3.capture3(env, *cmd, chdir: AFTER_HOOK_APP_DIR)
    expect(stderr).to include('after hook error (RuntimeError)')
    expect(status.exitstatus).to eq(1)
    expect(File.exist?("#{tmpdir}/#{env.fetch('FILENAME')}")).to eq(true)
  end
end
