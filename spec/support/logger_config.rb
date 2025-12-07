# frozen_string_literal: true

require 'fileutils'

# Redirect logger output to tmp file during tests
log_dir = File.expand_path('../../tmp', __dir__)
FileUtils.mkdir_p(log_dir)
test_log_file = File.open(File.join(log_dir, 'test.log'), 'w')
stdout_original = $stdout
$stdout = test_log_file

RSpec.configure do |config|
  config.after(:suite) do
    $stdout = stdout_original
    test_log_file.close
  end
end
