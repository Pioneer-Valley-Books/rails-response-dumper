# frozen_string_literal: true

module RailsResponseDumper
  DumpBlock = Struct.new('DumpBlock', :name, :expected_status_code, :block)
end
