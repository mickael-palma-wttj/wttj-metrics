# Helpers

This directory contains utility modules that provide common formatting and data manipulation functions used throughout the application.

## Modules

### DateHelper

Provides date manipulation and formatting utilities for working with weeks, dates, and time ranges.

**Key Methods:**
- `week_start_date(date)` - Returns the Monday of the week containing the given date
- `week_end_date(date)` - Returns the Sunday of the week containing the given date
- `format_week(date)` - Formats a date as "Week XX (Mon DD - Sun DD)"
- `weeks_between(start_date, end_date)` - Returns an array of week start dates between two dates
- `parse_date(date_string)` - Safely parses a date string, handling various formats

**Usage Example:**
```ruby
include WttjMetrics::Helpers::DateHelper

# Get week boundaries
start = week_start_date(Date.today)  # => Monday of current week
end_date = week_end_date(Date.today)  # => Sunday of current week

# Format for display
formatted = format_week(Date.today)  # => "Week 49 (Dec 02 - Dec 08)"

# Get all weeks in a range
weeks = weeks_between(Date.new(2024, 1, 1), Date.new(2024, 12, 31))
```

### FormattingHelper

Provides consistent formatting utilities for numbers, percentages, and durations used across presenters and reports.

**Key Methods:**
- `format_percentage(value, total)` - Calculates and formats a percentage (returns integer)
- `format_duration(hours)` - Converts hours to human-readable format (e.g., "2d 4h", "30m")
- `format_number(value)` - Formats numbers with thousand separators

**Usage Example:**
```ruby
include WttjMetrics::Helpers::FormattingHelper

# Format percentages (returns integers)
pct = format_percentage(25, 100)  # => 25 (not 25.0)

# Format durations
duration = format_duration(52.5)  # => "2d 4h"
short = format_duration(0.5)      # => "30m"

# Format large numbers
formatted = format_number(1234567)  # => "1,234,567"
```

### IssueHelper

Provides utilities for working with Linear issues, including filtering, status checking, and team assignments.

**Key Methods:**
- `bug_issue?(issue)` - Determines if an issue is a bug based on labels
- `team_for_issue(issue)` - Extracts team name from issue
- `in_progress?(issue)` - Checks if issue is currently in progress
- `completed?(issue)` - Checks if issue is completed
- `issue_state(issue, workflow_states)` - Gets the current state of an issue
- `filter_by_date_range(issues, start_date, end_date)` - Filters issues by date range

**Usage Example:**
```ruby
include WttjMetrics::Helpers::IssueHelper

# Check issue types
is_bug = bug_issue?(issue)  # => true/false based on labels

# Get team assignment
team = team_for_issue(issue)  # => "ATS" or "Global ATS"

# Check status
if in_progress?(issue)
  puts "Issue is being worked on"
elsif completed?(issue)
  puts "Issue is done"
end

# Filter issues by date
recent_issues = filter_by_date_range(all_issues, 30.days.ago, Date.today)
```

## Design Principles

1. **Single Responsibility**: Each helper focuses on a specific domain (dates, formatting, issues)
2. **Reusability**: Methods are designed to be used across multiple presenters and calculators
3. **Consistency**: Provides standardized formatting throughout the application
4. **Testability**: All helpers are fully unit tested with comprehensive test coverage

## Dependencies

- `date` - Ruby standard library for date manipulation
- `time` - Ruby standard library for time operations

## Testing

All helpers have comprehensive test coverage in `spec/wttj_metrics/helpers/`:
- `date_helper_spec.rb` - Tests for date calculations and formatting
- `formatting_helper_spec.rb` - Tests for number and percentage formatting
- `issue_helper_spec.rb` - Tests for issue filtering and status checking

Run tests with:
```bash
bundle exec rspec spec/wttj_metrics/helpers/
```
