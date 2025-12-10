# frozen_string_literal: true

source 'https://rubygems.org'

# Core
gem 'caxlsx', '~> 4.1'   # Excel export
gem 'csv', '~> 3.3'      # CSV parsing (required from Ruby 3.4+)
gem 'dotenv', '~> 3.1'   # Environment variables
gem 'octokit', '~> 10.0'
gem 'openssl', '~> 3.2'  # SSL/TLS support
gem 'ruby-progressbar', '~> 1.13'
gem 'thor', '~> 1.3'     # CLI framework
gem 'zeitwerk', '~> 2.6' # Autoloading

group :development do
  gem 'bundler-audit', '~> 0.9', require: false # Dependency vulnerability check
  gem 'reek', '~> 6.3', require: false # Code smell detector
  gem 'rubocop', '~> 1.68', require: false # Style linting
  gem 'rubocop-performance', '~> 1.23', require: false # Performance cops
  gem 'rubocop-rspec', '~> 3.8', require: false # RSpec cops
  gem 'ruby-lsp', require: false
  gem 'ruby-lsp-rspec', require: false
end

group :test do
  gem 'rspec', '~> 3.13'
  gem 'simplecov', '~> 0.22', require: false # Code coverage
  gem 'vcr', '~> 6.3'
  gem 'webmock', '~> 3.24'
end
