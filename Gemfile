# frozen_string_literal: true

source 'https://rubygems.org'

# Core
gem 'caxlsx', '~> 4.1'   # Excel export
gem 'csv', '~> 3.3'      # CSV parsing (required from Ruby 3.4+)
gem 'dotenv', '~> 3.1'   # Environment variables
gem 'thor', '~> 1.3'     # CLI framework
gem 'zeitwerk', '~> 2.6' # Autoloading

group :development do
  gem 'rubocop', '~> 1.68', require: false
  gem 'rubocop-rspec', '~> 3.8'
end

group :test do
  gem 'rspec', '~> 3.13'
  gem 'vcr', '~> 6.3'
  gem 'webmock', '~> 3.24'
end
