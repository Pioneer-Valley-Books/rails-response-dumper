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
    expect(stderr).to eq('')
    expect(stdout).to eq("....\n")
    expect(status.exitstatus).to eq(0)

    expect(File.join(APP_DIR, 'dumps')).to match_snapshots
  end

  context 'with --verbose argument' do
    it 'outputs dumper and dump block names' do
      cmd = %w[bundle exec rails-response-dumper --verbose]
      stdout, stderr, status = Open3.capture3(*cmd, chdir: APP_DIR)
      expect(stderr).to eq('')
      expect(stdout).to eq("Hooks.hook .\nRoot.index .\nTests.post_with_body .\nTests.multiple_requests .\n\n")
      expect(status.exitstatus).to eq(0)

      # The snapshot output remains the same with the verbose option
      expect(File.join(APP_DIR, 'dumps')).to match_snapshots
    end
  end

  context 'when run with --order' do
    context 'with type "random"' do
      it 'renders reproducible dumps with random seed' do
        cmd = %w[bundle exec rails-response-dumper --order random]
        stdout, stderr, status = Open3.capture3(*cmd, chdir: APP_DIR)
        expect(stderr).to eq('')
        expect(stdout).to match(/\ARandomized with seed [1-9][0-9]*\n\.\.\.\.\n\z/)
        expect(status.exitstatus).to eq(0)
        expect(File.join(APP_DIR, 'dumps')).to match_snapshots
      end
    end

    context 'when given a seed value' do
      it 'creates dump files in reproducible order' do
        cmd = %w[bundle exec rails-response-dumper --order 8 --verbose]
        stdout, stderr, status = Open3.capture3(*cmd, chdir: APP_DIR)
        expect(stderr).to eq('')
        expect(stdout).to eq <<~TEXT
          Randomized with seed 8
          Tests.post_with_body .
          Root.index .
          Hooks.hook .
          Tests.multiple_requests .

        TEXT
        expect(status.exitstatus).to eq(0)
        expect(File.join(APP_DIR, 'dumps')).to match_snapshots
      end
    end
  end

  it 'runs after hook when an exception is raised' do
    env = { 'TMPDIR' => tmpdir, 'FILENAME' => 'test.out' }
    cmd = %w[bundle exec rails-response-dumper]
    stdout, stderr, status = Open3.capture3(env, *cmd, chdir: AFTER_HOOK_APP_DIR)
    expect(stderr).to eq('')
    expect(stdout.lines[0]).to eq("F\n")
    expect(stdout).to include <<~ERR
      #{AFTER_HOOK_APP_DIR}/dumpers/after_hook_dumper.rb:8 after_hook.after_hook received after hook error
      #{AFTER_HOOK_APP_DIR}/dumpers/after_hook_dumper.rb:9:in `block (2 levels) in <top (required)>': after hook error (RuntimeError)
    ERR
    expect(status.exitstatus).to eq(1)
    expect(File.exist?("#{tmpdir}/#{env.fetch('FILENAME')}")).to eq(true)
  end

  context 'when there are errors in the dumpers' do
    let(:invalid_number_of_statuses) { 'fail_app.invalid_number_of_statuses' }
    let(:dumper_2_invalid_status_code) { 'fail_app_2.invalid_status_code' }

    it 'outputs all errors after execution' do
      cmd = %w[bundle exec rails-response-dumper]
      stdout, stderr, status = Open3.capture3(*cmd, chdir: FAIL_APP_DIR)
      expect(stderr).to eq('')
      expect(stdout.lines[0]).to eq("FFF\n")
      expect(stdout).to include <<~ERR
        #{FAIL_APP_DIR}/dumpers/fail_app_dumper.rb:4 fail_app.invalid_status_code received unexpected status code 200 OK (expected 404)
        #{Dir.getwd}/lib/rails_response_dumper/runner.rb:77:in `block (3 levels) in run_dumps': unexpected status code 200 OK (expected 404) (RuntimeError)
      ERR
      expect(stdout).to include <<~ERR
        #{FAIL_APP_DIR}/dumpers/fail_app_dumper.rb:8 #{invalid_number_of_statuses} received 2 responses (expected 1)
        #{Dir.getwd}/lib/rails_response_dumper/runner.rb:65:in `block (2 levels) in run_dumps': 2 responses (expected 1) (RuntimeError)
      ERR
      expect(stdout).to include <<~ERR
        #{FAIL_APP_DIR}/dumpers/fail_app_dumper_2.rb:4 #{dumper_2_invalid_status_code} received unexpected status code 200 OK (expected 404)
        #{Dir.getwd}/lib/rails_response_dumper/runner.rb:77:in `block (3 levels) in run_dumps': unexpected status code 200 OK (expected 404) (RuntimeError)
      ERR
      expect(status.exitstatus).to eq(1)
    end

    context 'with --fail-fast argument' do
      it 'aborts after the first error' do
        cmd = %w[bundle exec rails-response-dumper --fail-fast]
        stdout, stderr, status = Open3.capture3(*cmd, chdir: FAIL_APP_DIR)
        expect(stderr).to eq('')
        expect(stdout.lines[0]).to eq("F\n")
        expect(stdout).to include <<~ERR
          #{FAIL_APP_DIR}/dumpers/fail_app_dumper.rb:4 fail_app.invalid_status_code received unexpected status code 200 OK (expected 404)
          #{Dir.getwd}/lib/rails_response_dumper/runner.rb:77:in `block (3 levels) in run_dumps': unexpected status code 200 OK (expected 404) (RuntimeError)
        ERR
        expect(stdout).not_to include(invalid_number_of_statuses)
        expect(stdout).not_to include(dumper_2_invalid_status_code)
        expect(status.exitstatus).to eq(1)
      end
    end
  end
end
