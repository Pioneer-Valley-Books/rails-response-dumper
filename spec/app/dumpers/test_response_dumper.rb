# frozen_string_literal: true

ResponseDumper.define 'Test' do
  dump 'multiple_requests', status_codes: %i[ok no_content] do
    get root_path
    delete url_for(action: :destroy, controller: 'test')
  end
end
