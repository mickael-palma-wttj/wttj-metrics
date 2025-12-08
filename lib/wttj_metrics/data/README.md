# Data

This directory contains classes responsible for data persistence, caching, and file operations. These classes handle reading from and writing to CSV files and managing cached API responses.

## Architecture

The data layer provides abstraction for:
- CSV file operations (reading and writing)
- File-based caching for API responses
- Data parsing and organization

## Classes

### CsvParser

Parses CSV metrics data files and provides structured access to metrics by category and date.

**Responsibilities:**
- Read and parse CSV files with metrics data
- Organize metrics by category (bug, cycle, flow, team, timeseries)
- Provide filtered access to metrics by category and date
- Handle timeseries data with date range filtering

**Key Methods:**
```ruby
parser = CsvParser.new('tmp/metrics.csv')

# Get metrics for a specific category and date
bug_metrics = parser.metrics_for('bug', date: '2024-12-08')
# => [{ metric: 'total_bugs', value: 150, ... }, ...]

# Get today's metrics (default)
team_metrics = parser.metrics_for('team')

# Get timeseries data since a specific date
timeseries = parser.timeseries_for('bugs_opened', since: '2024-01-01')
# => [{ date: '2024-01-01', value: 10 }, { date: '2024-01-08', value: 15 }, ...]
```

**CSV Format:**
```csv
date,category,metric,value
2024-12-08,bug,total_bugs,150
2024-12-08,bug,open_bugs,15
2024-12-08,cycle,avg_scope_change,12
2024-12-08,team,ATS:velocity,25
```

**Features:**
- Liberal parsing mode to handle malformed CSV data
- Category-based organization for efficient lookups
- Date filtering for historical data analysis
- Timeseries support for trend analysis

### CsvWriter

Writes metrics data to CSV files with proper formatting and headers.

**Responsibilities:**
- Write new CSV files with headers
- Append data to existing CSV files
- Maintain consistent CSV format across writes
- Handle file creation and directory setup

**Key Methods:**
```ruby
writer = CsvWriter.new('tmp/metrics.csv')

# Write new file (overwrites existing)
rows = [
  ['2024-12-08', 'bug', 'total_bugs', 150],
  ['2024-12-08', 'bug', 'open_bugs', 15]
]
writer.write_rows(rows)

# Append to existing file
new_rows = [
  ['2024-12-09', 'bug', 'total_bugs', 152]
]
writer.append_rows(new_rows)
```

**CSV Headers:**
- `date` - Date of the metric (YYYY-MM-DD format)
- `category` - Metric category (bug, cycle, flow, team, timeseries)
- `metric` - Metric name (e.g., total_bugs, avg_completion)
- `value` - Metric value (numeric or string)

**Features:**
- Automatic header management
- Append mode for incremental updates
- Consistent formatting across all writes
- File existence checking

### FileCache

File-based caching system for API responses to reduce API calls and improve performance.

**Responsibilities:**
- Cache API responses as JSON files
- Check cache freshness based on max age
- Invalidate expired cache entries
- Clear cache on demand
- Provide logging for cache hits/misses

**Key Methods:**
```ruby
cache = FileCache.new('tmp/cache')

# Fetch with cache (24 hours default)
data = cache.fetch('issues_all') do
  # This block only runs on cache miss
  api_client.fetch_all_issues
end
# => First call: "🌐 Fetching issues_all from API..."
# => Subsequent calls: "📦 Using cached issues_all (2.5h old)"

# Custom max age
data = cache.fetch('cycles', max_age_hours: 6) do
  api_client.fetch_cycles
end

# Clear all cached data
cache.clear_all
# => "🧹 Clearing all cache files..."
```

**Cache Directory Structure:**
```
tmp/cache/
├── issues_all.json
├── cycles.json
├── team_members.json
└── workflow_states.json
```

**Features:**
- Automatic cache directory creation
- Age-based expiration (default 24 hours)
- JSON serialization for structured data
- Informative logging with emojis
- Block-based API for cache-miss handling
- Cache clearing functionality

**Configuration:**
- Default cache directory: `tmp/cache`
- Default max age: 24 hours
- Configurable per fetch call

## Usage Patterns

### Data Collection Workflow
```ruby
# 1. Fetch data with caching
cache = Data::FileCache.new
client = Sources::Linear::Client.new(cache: cache)
issues = client.fetch_all_issues  # Uses cache if fresh

# 2. Calculate metrics
calculator = Metrics::BugCalculator.new(issues, workflow_states)
metrics = calculator.calculate

# 3. Write to CSV
writer = Data::CsvWriter.new('tmp/metrics.csv')
rows = format_metrics_as_rows(metrics)
writer.write_rows(rows)
```

### Report Generation Workflow
```ruby
# 1. Read metrics from CSV
parser = Data::CsvParser.new('tmp/metrics.csv')

# 2. Get specific metrics
bug_data = parser.metrics_for('bug')
cycle_data = parser.metrics_for('cycle')
timeseries = parser.timeseries_for('bugs_opened', since: 30.days.ago)

# 3. Format for presentation
presenter = Presenters::BugMetricPresenter.new(bug_data)
```

## Design Principles

1. **Single Responsibility**: Each class handles one aspect of data persistence
2. **Separation of Concerns**: Reading/writing/caching are independent
3. **Fail-Safe Operations**: Graceful handling of missing files and corrupted data
4. **Performance**: Caching reduces API calls and speeds up report generation
5. **Transparency**: Detailed logging for debugging and monitoring

## File Locations

**Default Paths:**
- CSV output: `tmp/metrics.csv`
- Cache directory: `tmp/cache/`
- Report output: `tmp/report.html`

**Cache Files:**
- `issues_all.json` - All Linear issues (largest file ~5-10 MB)
- `cycles.json` - All cycles/sprints (~100-500 KB)
- `team_members.json` - Team member data (~10-50 KB)
- `workflow_states.json` - Workflow states (~5-10 KB)

## Performance Considerations

### Cache Strategy
- **API calls are expensive**: Linear API rate limits apply
- **Cache duration**: 24 hours balances freshness vs API usage
- **Cache size**: Issues file can be large (6000+ issues = ~10 MB JSON)
- **Cache invalidation**: Use `--clear-cache` flag to force fresh data

### CSV Performance
- **Liberal parsing**: Handles malformed CSV without crashing
- **Streaming**: CSV reading uses Ruby's efficient CSV parser
- **Memory usage**: Metrics CSV is small (~50-200 KB), loaded entirely into memory

## Error Handling

### FileCache
```ruby
# Cache miss - block executes
cache.fetch('missing_key') { fetch_from_api }

# Expired cache - block executes
cache.fetch('old_key', max_age_hours: 1) { fetch_fresh_data }

# Invalid JSON - raises error, cache file should be deleted
```

### CsvParser
```ruby
# Missing file - raises Errno::ENOENT
parser = CsvParser.new('nonexistent.csv')  # => Error

# Malformed CSV - uses liberal parsing
parser = CsvParser.new('bad_format.csv')   # => Warns but continues
```

### CsvWriter
```ruby
# Directory doesn't exist - CSV.open creates parent dirs if needed
writer = CsvWriter.new('deep/nested/path/file.csv')
writer.write_rows(rows)  # Creates directories automatically
```

## Testing

All data classes have comprehensive test coverage:
- `spec/wttj_metrics/data/csv_parser_spec.rb`
- `spec/wttj_metrics/data/csv_writer_spec.rb`
- `spec/wttj_metrics/data/file_cache_spec.rb`

Run tests:
```bash
bundle exec rspec spec/wttj_metrics/data/
```

## Dependencies

- `csv` - Ruby standard library for CSV operations
- `json` - Ruby standard library for JSON serialization
- `fileutils` - File system operations
- `logger` - Logging cache operations
- `date` - Date parsing and formatting

## Integration Points

**Used By:**
- `Services::DataFetcher` - Uses FileCache for API caching
- `Reports::ReportGenerator` - Uses CsvParser to read metrics
- `CLI` - Uses CsvWriter to save collected metrics

**Uses:**
- `WttjMetrics.root` - Root directory for relative paths
- Standard Ruby libraries (CSV, JSON, FileUtils)
