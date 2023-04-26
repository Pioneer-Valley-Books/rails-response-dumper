# frozen_string_literal: true

ResponseDumper.define 'Tests' do
  # update to have new params 'baz' -> 'bats'
  dump 'post_with_body', status_codes: %i[no_content no_content] do
    post url_for(controller: :tests, action: :create), params: { foo: { bar: 'bats' } }
    post url_for(controller: :tests, action: :create), as: :json, params: { foo: { bar: 'bats' } }
  end

  # new dump
  dump 'another_post', status_codes: %i[no_content] do
    post url_for(controller: :tests, action: :create), params: { hello: { world: '' } }
  end

  # 'multiple_requests' dump removed
end
