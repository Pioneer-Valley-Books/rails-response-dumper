# frozen_string_literal: true

ResponseDumper.define 'Tests' do
  dump 'multiple_requests', status_codes: %i[ok no_content] do
    get root_path
    delete url_for(controller: :tests, action: :destroy)
  end
end
