# frozen_string_literal: true

# Redirect logger output to tmp file during tests
test_log_file = File.open(File.expand_path('../../tmp/test.log', __dir__), 'w')
stdout_original = $stdout
$stdout = test_log_file

RSpec.configure do |config|
  config.after(:suite) do
    $stdout = stdout_original
    test_log_file.close
  end
end
