# frozen_string_literal: true

require 'open3'

RSpec::Matchers.define :match_snapshots do |snapshots = nil|
  match do |actual|
    snapshots ||= File.expand_path('../snapshots', actual)
    raise "Snapshot directory #{snapshots} does not exist" unless Dir.exist?(snapshots)

    cmd = ['diff', '--unified', '--recursive', actual, snapshots]
    @out, err, status = Open3.capture3(*cmd)

    case status.exitstatus
    when 0
      true
    when 1
      false
    else
      raise "Command failed with exit #{status}: #{cmd.join(' ')}\n\n#{err}"
    end
  end

  failure_message do |actual|
    <<~MSG
      Dumps at #{actual} do not match snapshots.

      #{@out}
    MSG
  end
end
