# frozen_string_literal: true

require 'json'
require 'open3'
require 'spec_helper'

APP_DIR = File.expand_path('test_apps/app', __dir__)
AFTER_HOOK_APP_DIR = File.expand_path('test_apps/after_hook', __dir__)
FAIL_APP_DIR = File.expand_path('test_apps/fail_app', __dir__)

RSpec.describe 'CLI' do
  let(:dumps_dir) { "#{tmpdir}/dumps" }

  before do
    ENV['DATABASE_URL'] = "sqlite3:#{tmpdir}/db"
    system({ 'RAILS_ENV' => 'test' }, 'bundle', 'exec', 'rails', 'db:schema:load', chdir: APP_DIR, exception: true)
  end

  after do
    ENV['DATABASE_URL'] = nil
  end

  it 'renders reproducible dumps' do
    dumps_dir = File.join(APP_DIR, 'dumps')

    begin
      cmd = %w[bundle exec rails-response-dumper --exclude-timestamp]
      stdout, stderr, status = Open3.capture3(*cmd, chdir: APP_DIR)
      expect(stderr).to eq('')
      expect(stdout).to eq(".....\n")
      expect(status.exitstatus).to eq(0)

      # defaults to 'dumps' directory
      expect(dumps_dir).to match_snapshots
    ensure
      FileUtils.rm_rf dumps_dir
    end
  end

  context 'with --verbose argument' do
    it 'outputs dumper and dump block names' do
      cmd = %W[bundle exec rails-response-dumper --verbose --dumps-dir #{dumps_dir} --exclude-timestamp]
      stdout, stderr, status = Open3.capture3(*cmd, chdir: APP_DIR)
      expect(stderr).to eq('')
      expect(stdout).to eq <<~TEXT
        Books.create .
        Hooks.hook .
        Root.index .
        Tests.post_with_body .
        Tests.multiple_requests .

      TEXT
      expect(status.exitstatus).to eq(0)

      # The snapshot output remains the same with the verbose option
      expect(dumps_dir).to match_snapshots(File.join(APP_DIR, 'snapshots'))
    end
  end

  context 'with --profile argument' do
    it 'outputs timing information' do
      cmd = %W[bundle exec rails-response-dumper --profile --dumps-dir #{dumps_dir} --exclude-timestamp]
      stdout, stderr, status = Open3.capture3(*cmd, chdir: APP_DIR)
      expect(stderr).to eq('')
      expect(stdout).to match(/^Books\.create \d+.\d{2} s$/)
      expect(status.exitstatus).to eq(0)

      # The snapshot output remains the same with the profile option.
      expect(dumps_dir).to match_snapshots(File.join(APP_DIR, 'snapshots'))
    end
  end

  context 'with --exclude-response-headers argument' do
    it 'renders dumps without response headers' do
      cmd = %W[
        bundle exec rails-response-dumper
        --exclude-response-headers
        --dumps-dir #{dumps_dir}
        --exclude-timestamp
      ]
      stdout, stderr, status = Open3.capture3(*cmd, chdir: APP_DIR)
      expect(stderr).to eq('')
      expect(stdout).to eq(".....\n")
      expect(status.exitstatus).to eq(0)

      expect(dumps_dir).to match_snapshots(File.join(APP_DIR, 'snapshots_without_response_headers'))
    end
  end

  context 'when run with --order' do
    context 'with type "random"' do
      it 'renders reproducible dumps with random seed' do
        cmd = %W[bundle exec rails-response-dumper --order random --dumps-dir #{dumps_dir} --exclude-timestamp]
        stdout, stderr, status = Open3.capture3(*cmd, chdir: APP_DIR)
        expect(stderr).to eq('')
        expect(stdout).to match(/\ARandomized with seed [1-9][0-9]*\n\.\.\.\.\.\n\z/)
        expect(status.exitstatus).to eq(0)
        expect(dumps_dir).to match_snapshots(File.join(APP_DIR, 'snapshots'))
      end
    end

    context 'when given a seed value' do
      it 'creates dump files in reproducible order' do
        cmd = %W[bundle exec rails-response-dumper --order 8 --verbose --dumps-dir #{dumps_dir} --exclude-timestamp]
        stdout, stderr, status = Open3.capture3(*cmd, chdir: APP_DIR)
        expect(stderr).to eq('')
        expect(stdout).to eq <<~TEXT
          Randomized with seed 8
          Tests.multiple_requests .
          Root.index .
          Hooks.hook .
          Books.create .
          Tests.post_with_body .

        TEXT
        expect(status.exitstatus).to eq(0)
        expect(dumps_dir).to match_snapshots(File.join(APP_DIR, 'snapshots'))
      end
    end
  end

  it 'runs after hook when an exception is raised' do
    env = { 'TMPDIR' => tmpdir, 'FILENAME' => 'test.out' }
    cmd = %W[bundle exec rails-response-dumper --dumps-dir #{dumps_dir} --exclude-timestamp]
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

  it 'executes model after_commit hooks' do
    env = { 'AFTER_COMMIT' => '1' }
    cmd = %W[bundle exec rails-response-dumper --dumps-dir #{dumps_dir} --exclude-timestamp]
    stdout, stderr, status = Open3.capture3(env, *cmd, chdir: APP_DIR)
    expect(stderr).to eq('')
    expect(stdout).to eq("Commit Book\n.....\n")
    expect(status.exitstatus).to eq(0)
    expect(dumps_dir).to match_snapshots(File.join(APP_DIR, 'snapshots'))
  end

  context 'when there are errors in the dumpers' do
    let(:invalid_number_of_statuses) { 'fail_app.invalid_number_of_statuses' }
    let(:dumper_2_invalid_status_code) { 'fail_app_2.invalid_status_code' }

    it 'outputs all errors after execution' do
      cmd = %W[bundle exec rails-response-dumper --dumps-dir #{dumps_dir} --exclude-timestamp]
      stdout, stderr, status = Open3.capture3(*cmd, chdir: FAIL_APP_DIR)
      expect(stderr).to eq('')
      expect(stdout.lines[0]).to eq("FFF\n")
      expect(stdout).to include <<~ERR
        #{FAIL_APP_DIR}/dumpers/fail_app_dumper.rb:4 fail_app.invalid_status_code received unexpected status code 200 OK (expected 404)
        #{Dir.getwd}/lib/rails_response_dumper/runner.rb:95:in `block (3 levels) in run_dumps': unexpected status code 200 OK (expected 404) (RuntimeError)
      ERR
      expect(stdout).to include <<~ERR
        #{FAIL_APP_DIR}/dumpers/fail_app_dumper.rb:8 #{invalid_number_of_statuses} received 2 responses (expected 1)
        #{Dir.getwd}/lib/rails_response_dumper/runner.rb:83:in `block (2 levels) in run_dumps': 2 responses (expected 1) (RuntimeError)
      ERR
      expect(stdout).to include <<~ERR
        #{FAIL_APP_DIR}/dumpers/fail_app_other_dumper.rb:4 #{dumper_2_invalid_status_code} received unexpected status code 200 OK (expected 404)
        #{Dir.getwd}/lib/rails_response_dumper/runner.rb:95:in `block (3 levels) in run_dumps': unexpected status code 200 OK (expected 404) (RuntimeError)
      ERR
      expect(status.exitstatus).to eq(1)
    end

    context 'with --fail-fast argument' do
      it 'aborts after the first error' do
        cmd = %W[bundle exec rails-response-dumper --fail-fast --dumps-dir #{dumps_dir} --exclude-timestamp]
        stdout, stderr, status = Open3.capture3(*cmd, chdir: FAIL_APP_DIR)
        expect(stderr).to eq('')
        expect(stdout.lines[0]).to eq("F\n")
        expect(stdout).to include <<~ERR
          #{FAIL_APP_DIR}/dumpers/fail_app_dumper.rb:4 fail_app.invalid_status_code received unexpected status code 200 OK (expected 404)
          #{Dir.getwd}/lib/rails_response_dumper/runner.rb:95:in `block (3 levels) in run_dumps': unexpected status code 200 OK (expected 404) (RuntimeError)
        ERR
        expect(stdout).not_to include(invalid_number_of_statuses)
        expect(stdout).not_to include(dumper_2_invalid_status_code)
        expect(status.exitstatus).to eq(1)
      end
    end
  end

  context 'with filename argument' do
    context 'without previous dumps' do
      context 'with one file specified' do
        it 'only runs dumps from that file' do
          cmd = %W[
            bundle exec rails-response-dumper
            --dumps-dir #{dumps_dir}
            --exclude-timestamp
            dumpers/tests_response_dumper.rb
          ]
          stdout, stderr, status = Open3.capture3(*cmd, chdir: APP_DIR)

          expect(dumps_dir).to match_snapshots(File.join(APP_DIR, 'snapshots_single_file'))

          expect(stderr).to eq('')
          expect(stdout).to eq("..\n")
          expect(status.exitstatus).to eq(0)
        end
      end

      context 'with two files specified' do
        it 'runs dumps from both files' do
          cmd = %W[
            bundle exec rails-response-dumper
            --dumps-dir #{dumps_dir}
            --exclude-timestamp
            dumpers/tests_response_dumper.rb dumpers/root_response_dumper.rb
          ]
          stdout, stderr, status = Open3.capture3(*cmd, chdir: APP_DIR)

          expect(dumps_dir).to match_snapshots(File.join(APP_DIR, 'snapshots_two_files'))

          expect(stderr).to eq('')
          expect(stdout).to eq("...\n")
          expect(status.exitstatus).to eq(0)
        end
      end
    end

    context 'with previous dumps' do
      before do
        cmd = %W[bundle exec rails-response-dumper --dumps-dir #{dumps_dir} --exclude-timestamp]
        Open3.capture3(*cmd, chdir: APP_DIR)
      end

      context 'with no changes to the dump file' do
        it 'does not alter the existing dumps from any file' do
          cmd = %W[
            bundle exec rails-response-dumper
            --dumps-dir #{dumps_dir}
            --exclude-timestamp
            dumpers/tests_response_dumper.rb
          ]
          stdout, stderr, status = Open3.capture3(*cmd, chdir: APP_DIR)

          expect(dumps_dir).to match_snapshots(File.join(APP_DIR, 'snapshots'))

          expect(stderr).to eq('')
          expect(stdout).to eq("..\n")
          expect(status.exitstatus).to eq(0)
        end
      end

      context 'with changes to the dump file' do
        it 'applies updates from the new dump file' do
          cmd = %W[
            bundle exec rails-response-dumper
            --dumps-dir #{dumps_dir}
            --exclude-timestamp
            configurable_dumpers/tests_response_dumper.rb
          ]
          # command references dumper file with same name but updated contents
          # to replicate re-running a dump after editing a file

          stdout, stderr, status = Open3.capture3(*cmd, chdir: APP_DIR)

          # deletes any dumps that no longer exist in specified file
          # updates altered dumps in specified file
          # creates new dumps if added to the file
          # does not delete dumps from non-specified files
          expect(dumps_dir).to match_snapshots(File.join(APP_DIR, 'snapshots_updated_dump'))

          expect(stderr).to eq('')
          expect(stdout).to eq("..\n")
          expect(status.exitstatus).to eq(0)
        end
      end
    end
  end

  context 'without the --exclude-timestamp argument' do
    it 'includes a ISO 8601 timestamp in each dump' do
      cmd = %W[bundle exec rails-response-dumper --dumps-dir #{dumps_dir}]
      stdout, stderr, status = Open3.capture3(*cmd, chdir: APP_DIR)
      expect(stderr).to eq('')
      expect(stdout).to eq(".....\n")
      expect(status.exitstatus).to eq(0)

      dumps = Dir.glob("#{dumps_dir}/**/*.json")
      expect(dumps.length).to eq(7)
      dumps.each do |path|
        dump = JSON.parse!(File.read(path))
        expect(dump['timestamp']).to match(/\A\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d:[0-5]\dZ\z/)
      end
    end
  end
end
