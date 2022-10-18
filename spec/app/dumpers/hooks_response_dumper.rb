# frozen_string_literal: true

ResponseDumper.define 'Hooks' do
  before do
    RootController.test_attribute = 'Test'
  end

  after do
    RootController.test_attribute = nil
  end

  dump 'hook' do
    get root_path
  end
end
