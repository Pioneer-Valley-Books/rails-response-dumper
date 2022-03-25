# frozen_string_literal: true

ResponseDumper.define 'Root' do
  dump 'index' do
    get root_path
  end
end
