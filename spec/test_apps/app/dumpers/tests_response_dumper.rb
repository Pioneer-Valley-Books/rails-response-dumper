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

  dump 'multipart_formdata_request_with_file', status_codes: %i[no_content] do
    mocked_image_file = Rack::Test::UploadedFile.new(
      StringIO.new("\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0d\x49\x48\x44\x52\x00\x00\x00\x02\x00\x00\x00\x01"),
      'image/png',
      true,
      original_filename: 'fake_image_file.png'
    )

    post url_for(controller: :tests, action: :submit_image), params: { uploaded_image_file: mocked_image_file }
  end
end
