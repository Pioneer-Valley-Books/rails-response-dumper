# frozen_string_literal: true

ResponseDumper.define 'fail_app_2' do
  dump 'invalid_status_code', status_codes: [:not_found] do
    get root_path
  end
end
