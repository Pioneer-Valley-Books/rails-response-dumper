# frozen_string_literal: true

ResponseDumper.define 'fail_app_duplicate' do
  dump 'duplicate' do
    get root_path
  end

  # A second dump with the same name writes to the same files as the first.
  dump 'duplicate' do
    get root_path
  end
end
