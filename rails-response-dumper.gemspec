# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'rails-response-dumper'
  spec.version = '1.0.0'
  spec.licenses = ['MIT']
  spec.summary = 'This is an example!'
  spec.authors = ['Pioneer Valley Books']

  spec.executables = ['rails-response-dumper']

  spec.homepage = 'https://github.com/Pioneer-Valley-Books/rails-response-dumper'
  spec.metadata = { 'rubygems_mfa_required' => 'true' }
  spec.required_ruby_version = '>= 3.0'
  spec.add_dependency 'rails', '>= 6.1'
end
