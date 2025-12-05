# frozen_string_literal: true

require 'webmock/rspec'
require 'vcr'

# Disable external connections by default
WebMock.disable_net_connect!

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter sensitive data
  config.filter_sensitive_data('<LINEAR_API_KEY>') { ENV.fetch('LINEAR_API_KEY', nil) }

  # Allow localhost for local testing
  config.ignore_localhost = true

  # Record mode - use :none in CI, :new_episodes for development
  config.default_cassette_options = {
    record: :none,
    match_requests_on: %i[method uri]
  }
end
