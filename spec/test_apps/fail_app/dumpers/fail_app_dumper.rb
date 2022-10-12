# frozen_string_literal: true

ResponseDumper.define 'fail_app' do
  dump 'invalid_status_code', status_codes: [:not_found] do
    get root_path
  end

  dump 'invalid_number_of_statuses', status_codes: [:ok] do
    get root_path
    get root_path
  end
end
