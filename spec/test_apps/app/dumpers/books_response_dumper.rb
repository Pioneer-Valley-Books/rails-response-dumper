# frozen_string_literal: true

ResponseDumper.define 'Books' do
  dump 'create', status_codes: %i[no_content] do
    post url_for(controller: :books, action: :create)
  end
end
