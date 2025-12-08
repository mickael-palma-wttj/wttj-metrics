# Values

This directory contains value objects that encapsulate command-line options and configuration data. Value objects are immutable data structures that group related values together.

## Architecture

Value objects follow these principles:
- **Immutability**: Once created, cannot be modified
- **Validation**: Can validate their own data on initialization
- **Equality**: Two value objects with same values are equal
- **No Behavior**: Pure data containers, no business logic
- **Type Safety**: Provide type-safe access to configuration

## Value Objects

### CollectOptions

Encapsulates options for the `collect` command which fetches data from Linear and saves metrics.

**Attributes:**
- `output` (String) - Path to output CSV file for metrics
- `cache_enabled` (Boolean) - Whether to use file cache for API responses
- `clear_cache` (Boolean) - Whether to clear cache before fetching

**Usage:**
```ruby
options = CollectOptions.new(
  output: 'tmp/metrics.csv',
  cache: true,
  clear_cache: false
)

puts options.output          # => "tmp/metrics.csv"
puts options.cache_enabled   # => true
puts options.clear_cache     # => false
```

**Created By:**
```ruby
# In CLI
options = CollectOptions.new({
  output: parsed_options[:output] || 'tmp/metrics.csv',
  cache: parsed_options.fetch(:cache, true),
  clear_cache: parsed_options[:clear_cache] || false
})

# Pass to service
collector = Services::DataFetcher.new(
  cache: options.cache_enabled ? CacheFactory.enabled : CacheFactory.disabled
)
```

**Default Values:**
- `output`: `'tmp/metrics.csv'`
- `cache_enabled`: `true`
- `clear_cache`: `false`

### ReportOptions

Encapsulates options for the `report` command which generates HTML reports.

**Attributes:**
- `days` (Integer) - Number of days to include in report (date range)
- `output` (String) - Path to output HTML file
- `input` (String) - Path to input CSV file with metrics
- `open` (Boolean) - Whether to open report in browser after generation

**Usage:**
```ruby
options = ReportOptions.new(
  days: 90,
  output: 'tmp/report.html',
  input: 'tmp/metrics.csv',
  open: false
)

puts options.days     # => 90
puts options.output   # => "tmp/report.html"
puts options.input    # => "tmp/metrics.csv"
puts options.open     # => false
```

**Created By:**
```ruby
# In CLI
options = ReportOptions.new({
  days: parsed_options[:days] || 90,
  output: parsed_options[:output] || 'tmp/report.html',
  input: parsed_options[:input] || 'tmp/metrics.csv',
  open: parsed_options[:open] || false
})

# Pass to service
service = Services::ReportService.new(options)
service.call
```

**Default Values:**
- `days`: `90`
- `output`: `'tmp/report.html'`
- `input`: `'tmp/metrics.csv'`
- `open`: `false`

## Usage Patterns

### CLI Command Pattern
```ruby
# 1. Parse command-line arguments
parsed_options = OptionParser.parse(ARGV)

# 2. Create value object
options = ReportOptions.new(parsed_options)

# 3. Pass to service
service = SomeService.new(options)
service.call

# 4. Access options in service
class SomeService
  def initialize(options)
    @options = options
  end

  def call
    generator = ReportGenerator.new(@options.input, days: @options.days)
    generator.generate(@options.output)
    
    open_in_browser if @options.open
  end
end
```

### Validation Pattern
```ruby
class ReportOptions
  def initialize(options_hash)
    @days = validate_days(options_hash[:days])
    @output = validate_output(options_hash[:output])
    @input = validate_input(options_hash[:input])
    @open = !!options_hash[:open]
  end

  private

  def validate_days(days)
    raise ArgumentError, "days must be positive" if days && days <= 0
    days || 90
  end

  def validate_output(path)
    raise ArgumentError, "output path required" if path.nil? || path.empty?
    path
  end
end
```

### Immutability Pattern
```ruby
# Value objects are immutable
options = ReportOptions.new(days: 90)

# No setters - this would fail
# options.days = 120  # => NoMethodError

# To change values, create a new instance
new_options = ReportOptions.new(
  days: 120,
  output: options.output,
  input: options.input,
  open: options.open
)
```

## Design Principles

1. **Immutability**: No setters, values set once in constructor
2. **Validation**: Validate data on initialization, fail fast
3. **Defaults**: Provide sensible defaults for optional values
4. **Type Safety**: Use specific types (Integer, String, Boolean)
5. **Simple Interface**: Attr_readers only, no methods
6. **Single Purpose**: One value object per command/context

## Benefits

### Type Safety
```ruby
# Without value object (error-prone)
def generate_report(days, output, input, open)
  # Easy to mix up parameters
end
generate_report('tmp/report.html', 90, 'tmp/metrics.csv', false)  # Wrong order!

# With value object (type-safe)
def generate_report(options)
  # Can't mix up parameters
end
generate_report(ReportOptions.new(days: 90, output: 'tmp/report.html'))  # Clear!
```

### Maintainability
```ruby
# Without value object - changing signature breaks callers
def collect_data(output, cache, clear_cache, format, verbose)
  # Adding new parameter requires changing all callers
end

# With value object - adding new option is easy
class CollectOptions
  attr_reader :output, :cache_enabled, :clear_cache, :format, :verbose
  # Just add new attr_reader, existing code still works
end
```

### Testability
```ruby
# Easy to create test fixtures
let(:default_options) { CollectOptions.new(output: 'test.csv', cache: false) }
let(:cached_options) { CollectOptions.new(output: 'test.csv', cache: true) }

# Easy to test with different configurations
it 'generates report with custom days' do
  options = ReportOptions.new(days: 30, output: 'test.html')
  service = ReportService.new(options)
  expect(service.call).to be_successful
end
```

## Command-Line Mappings

### Collect Command
```bash
wttj-metrics collect --output tmp/metrics.csv --cache --clear-cache
```
Maps to:
```ruby
CollectOptions.new(
  output: 'tmp/metrics.csv',
  cache: true,
  clear_cache: true
)
```

### Report Command
```bash
wttj-metrics report --days 90 --output report.html --input metrics.csv --open
```
Maps to:
```ruby
ReportOptions.new(
  days: 90,
  output: 'report.html',
  input: 'metrics.csv',
  open: true
)
```

## Testing

Value objects are typically tested for:
- Proper initialization
- Attribute access
- Default values
- Validation (if implemented)
- Immutability

Example tests:
```ruby
RSpec.describe CollectOptions do
  describe '#initialize' do
    it 'sets all attributes from hash' do
      options = CollectOptions.new(
        output: 'test.csv',
        cache: false,
        clear_cache: true
      )
      
      expect(options.output).to eq('test.csv')
      expect(options.cache_enabled).to be false
      expect(options.clear_cache).to be true
    end
  end

  describe 'defaults' do
    it 'uses default values when not provided' do
      options = CollectOptions.new({})
      
      expect(options.cache_enabled).to be true
      expect(options.clear_cache).to be false
    end
  end
end
```

## Future Enhancements

### Potential New Value Objects

1. **ExportOptions** - For exporting to different formats (CSV, Excel, JSON)
   ```ruby
   ExportOptions.new(format: :excel, output: 'report.xlsx')
   ```

2. **FilterOptions** - For filtering data (teams, date ranges, priorities)
   ```ruby
   FilterOptions.new(teams: ['ATS'], priority: 'High', since: 30.days.ago)
   ```

3. **ChartOptions** - For customizing chart appearance
   ```ruby
   ChartOptions.new(theme: :dark, width: 1200, height: 600)
   ```

4. **NotificationOptions** - For sending reports via email/Slack
   ```ruby
   NotificationOptions.new(email: 'team@example.com', slack_channel: '#metrics')
   ```

## Dependencies

**Internal:**
- None (value objects are pure data, no dependencies)

**External:**
- None (uses only Ruby standard library)

## Integration Points

**Used By:**
- `CLI` - Creates value objects from command-line arguments
- `Services::*` - Receives value objects as parameters

**Uses:**
- None (leaf nodes in dependency graph)

## Best Practices

1. **Keep Simple**: Value objects should be simple data containers
2. **Validate Early**: Validate in constructor, fail fast on invalid data
3. **Provide Defaults**: Make optional parameters easy to use
4. **Document Attributes**: Clearly document what each attribute represents
5. **One Per Context**: Create separate value objects for different commands/contexts
6. **No Business Logic**: Keep business logic in services, not value objects
7. **Immutable**: Never add setters, create new instances instead
