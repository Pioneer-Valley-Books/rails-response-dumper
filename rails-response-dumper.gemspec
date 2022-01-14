# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'rails-response-dumper'
  spec.version = '1.1.0'
  spec.licenses = ['MIT']
  spec.summary = 'Dump HTTP responses from a Rails application to the file system'
  spec.authors = ['Pioneer Valley Books']
  spec.description = <<~DESC
    Rails Response Dumper is a library and command line tool to dump HTTP
    responses from a Rails application to the file system. These responses can
    then be consumed by other tools for testing and verification purposes.
  DESC

  spec.executables = ['rails-response-dumper']

  spec.homepage = 'https://github.com/Pioneer-Valley-Books/rails-response-dumper'
  spec.metadata = { 'rubygems_mfa_required' => 'true' }
  spec.required_ruby_version = '>= 3.0'
  spec.add_dependency 'rails', '>= 6.1', '< 8'
end
