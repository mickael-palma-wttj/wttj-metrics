# frozen_string_literal: true

# Suppress warnings from external gems
$VERBOSE = nil

# Load the library
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'wttj_metrics'

# Load support files
Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }
