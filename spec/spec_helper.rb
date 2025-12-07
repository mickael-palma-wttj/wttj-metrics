# frozen_string_literal: true

# Code coverage - must be first
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
  enable_coverage :branch
  minimum_coverage line: 80, branch: 65
end

# Suppress warnings from external gems
$VERBOSE = nil

# Load the library
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'wttj_metrics'

# Load support files
Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }
