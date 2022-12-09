# frozen_string_literal: true

ResponseDumper.define 'Tests' do
  dump 'post_with_body', status_codes: %i[no_content no_content] do
    post url_for(controller: :tests, action: :create), params: { foo: { bar: 'baz' } }
    post url_for(controller: :tests, action: :create), as: :json, params: { foo: { bar: 'baz' } }
  end

  dump 'multiple_requests', status_codes: %i[ok no_content] do
    get root_path
    delete url_for(controller: :tests, action: :destroy)
  end
end
