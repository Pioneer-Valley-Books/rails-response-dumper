# frozen_string_literal: true

require 'open3'
require 'spec_helper'

APP_DIR = File.expand_path('test_apps/app', __dir__)
AFTER_HOOK_APP_DIR = File.expand_path('test_apps/after_hook', __dir__)
FAIL_APP_DIR = File.expand_path('test_apps/fail_app', __dir__)

RSpec.describe 'CLI' do
  it 'renders reproducible dumps' do
    cmd = %w[bundle exec rails-response-dumper]
    stdout, stderr, status = Open3.capture3(*cmd, chdir: APP_DIR)

    expect(stdout).to eq("...\n")
    expect(stderr).to eq('')
    expect(status.exitstatus).to eq(0)

    expect(File.join(APP_DIR, 'dumps')).to match_snapshots
  end

  it 'runs after hook when an exception is raised' do
    env = { 'TMPDIR' => tmpdir, 'FILENAME' => 'test.out' }
    cmd = %w[bundle exec rails-response-dumper]
    stdout, stderr, status = Open3.capture3(env, *cmd, chdir: AFTER_HOOK_APP_DIR)
    expect(stdout).to eq("F\n")
    expect(stderr).to include <<~ERR
      #{AFTER_HOOK_APP_DIR}/dumpers/after_hook_dumper.rb:8 after_hook.after_hook received after hook error
      #{AFTER_HOOK_APP_DIR}/dumpers/after_hook_dumper.rb:9:in `block (2 levels) in <top (required)>'
    ERR
    expect(status.exitstatus).to eq(1)
    expect(File.exist?("#{tmpdir}/#{env.fetch('FILENAME')}")).to eq(true)
  end

  it 'outputs all errors after execution' do
    cmd = %w[bundle exec rails-response-dumper]
    stdout, stderr, status = Open3.capture3(*cmd, chdir: FAIL_APP_DIR)
    expect(stdout).to eq("FF\n")
    expect(stderr).to include <<~ERR
      #{FAIL_APP_DIR}/dumpers/fail_app_dumper.rb:4 fail_app.invalid_status_code received unexpected status code 200 OK (expected 404)
      #{Dir.getwd}/lib/rails_response_dumper/runner.rb:47:in `block (3 levels) in run_dumps'

      #{FAIL_APP_DIR}/dumpers/fail_app_dumper.rb:8 fail_app.invalid_number_of_statuses received 2 responses (expected 1)
      #{Dir.getwd}/lib/rails_response_dumper/runner.rb:35:in `block (2 levels) in run_dumps'
    ERR
    expect(status.exitstatus).to eq(1)
  end
end
