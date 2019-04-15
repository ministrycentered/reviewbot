# frozen_string_literal: true
VCR.configure do |config|
  config.cassette_library_dir = 'spec/support/vcr_cassettes'
  config.hook_into :webmock
  config.filter_sensitive_data('<TOKEN>') { ENV['GH_AUTH_TOKEN'] }
  config.allow_http_connections_when_no_cassette = false
end
