# Presenters

This directory contains presenter classes that format and prepare metric data for display in the HTML report. Presenters act as a bridge between raw metric calculations and the user-facing report template.

## Architecture

All presenters inherit from `BasePresenter` and follow the **Presenter Pattern**:
- Accept raw data in the initializer
- Provide formatting methods for display
- Handle edge cases and nil values gracefully
- Return HTML-safe strings for the ERB template

## Presenters

### BasePresenter

Abstract base class providing common functionality for all presenters.

**Features:**
- Includes all helper modules (DateHelper, FormattingHelper, IssueHelper)
- Provides shared utility methods
- Defines consistent interface for child presenters

**Common Methods:**
- `safe_percentage(value)` - Safely formats percentages, returns "N/A" for invalid values
- `safe_number(value)` - Safely formats numbers, returns "0" for nil
- `status_badge(status)` - Returns CSS class for status badges

### BugMetricPresenter

Formats bug-related metrics for display including status, priority, MTTR, and resolution rates.

**Responsibilities:**
- Format bug counts and percentages
- Generate CSS classes for bug status badges
- Format MTTR (Mean Time To Resolution) as human-readable durations
- Calculate and format resolution rates

**Key Methods:**
```ruby
presenter = BugMetricPresenter.new(bug_data)

# Get formatted metrics
presenter.total_bugs              # => "150"
presenter.open_bugs               # => "15"
presenter.mttr                    # => "2d 4h"
presenter.resolution_rate         # => "85%"
presenter.status_badge_class(:open)  # => "badge-warning"
```

**CSS Classes:**
- `badge-danger` - Open bugs (red)
- `badge-info` - In Progress bugs (blue)
- `badge-success` - Completed bugs (green)
- `badge-secondary` - Cancelled bugs (gray)

### BugTeamPresenter

Formats team-specific bug metrics for the Bug Stats by Team table.

**Responsibilities:**
- Format team names for display
- Calculate and format bug percentages by team
- Generate resolution rate badges with appropriate styling
- Format MTTR per team

**Key Methods:**
```ruby
presenter = BugTeamPresenter.new(team_name, team_data)

# Get formatted team metrics
presenter.team_name               # => "ATS"
presenter.open_bugs               # => "10"
presenter.resolved_bugs           # => "40"
presenter.resolution_rate         # => "80%"
presenter.resolution_rate_class   # => "badge-success"
presenter.mttr_formatted          # => "1d 8h"
```

**Resolution Rate Styling:**
- `badge-success` - ≥ 80% (green)
- `badge-warning` - 50-79% (yellow)
- `badge-danger` - < 50% (red)

### CyclePresenter

Formats cycle-related metrics including scope changes, completion rates, and progress.

**Responsibilities:**
- Format cycle names and date ranges
- Calculate and format scope change percentages
- Display completion rates with color coding
- Show progress bars for active cycles
- Format issue counts (planned, added, completed)

**Key Methods:**
```ruby
presenter = CyclePresenter.new(cycle_data)

# Get formatted cycle info
presenter.name                    # => "Sprint 2024-W49"
presenter.date_range              # => "Dec 02 - Dec 08, 2024"
presenter.scope_change_rate       # => "15%"
presenter.completion_rate         # => "85"
presenter.completion_rate_class   # => "completion-high"
presenter.progress_bar_width      # => "85"
```

**Completion Rate Classes:**
- `completion-high` - ≥ 80% (green)
- `completion-medium` - 50-79% (yellow)
- `completion-low` - < 50% (red)

### CycleMetricPresenter

Formats aggregated cycle metrics and statistics across all cycles.

**Responsibilities:**
- Calculate average scope change across cycles
- Format total cycle count
- Display completion statistics (min, max, average)
- Format velocity metrics

**Key Methods:**
```ruby
presenter = CycleMetricPresenter.new(all_cycles)

# Get aggregated metrics
presenter.total_cycles            # => "24"
presenter.avg_scope_change        # => "12%"
presenter.avg_completion          # => "78%"
presenter.min_completion          # => "45%"
presenter.max_completion          # => "100%"
```

### FlowMetricPresenter

Formats flow metrics including throughput, cycle time, and work in progress.

**Responsibilities:**
- Format throughput data for charts
- Display cycle time trends
- Show work in progress (WIP) counts
- Calculate flow efficiency percentages

**Key Methods:**
```ruby
presenter = FlowMetricPresenter.new(flow_data)

# Get formatted flow metrics
presenter.avg_throughput          # => "25 issues/week"
presenter.avg_cycle_time          # => "5.2 days"
presenter.current_wip             # => "45"
presenter.flow_efficiency         # => "65%"
presenter.weekly_throughput       # => { "2024-W49" => 25, ... }
```

### TeamMetricPresenter

Formats team comparison metrics showing performance across teams.

**Responsibilities:**
- Format team names for comparison table
- Display velocity metrics per team
- Calculate and format bug rates
- Show completion rates with progress bars
- Format cycle time averages

**Key Methods:**
```ruby
presenter = TeamMetricPresenter.new(team_name, team_metrics)

# Get formatted team metrics
presenter.team_name               # => "ATS"
presenter.velocity                # => "12 issues/week"
presenter.bug_rate                # => "8%"
presenter.avg_completion          # => "82"
presenter.avg_cycle_time          # => "4.5 days"
presenter.completion_class        # => "completion-high"
```

## Usage in Templates

Presenters are instantiated in the ERB template and used to format data:

```erb
<% cycle_presenter = CyclePresenter.new(cycle_data) %>
<tr>
  <td><%= cycle_presenter.name %></td>
  <td><%= cycle_presenter.date_range %></td>
  <td>
    <span class="badge badge-primary">
      <%= cycle_presenter.scope_change_rate %>
    </span>
  </td>
  <td>
    <div class="progress">
      <div class="progress-fill <%= cycle_presenter.completion_rate_class %>"
           style="width: <%= cycle_presenter.progress_bar_width %>%">
      </div>
    </div>
  </td>
</tr>
```

## Data Flow

```
Raw Metric Data (from Calculators)
      ↓
[Presenter.new(data)]
      ↓
Presenter Instance
      ↓
Template calls presenter.method
      ↓
Formatted, HTML-safe output
      ↓
Displayed in HTML Report
```

## Design Principles

1. **Single Responsibility**: Each presenter handles one data type (bugs, cycles, teams, etc.)
2. **View Logic Only**: No business logic, only formatting and display concerns
3. **Safe Defaults**: Handle nil/missing data gracefully with fallback values
4. **Testability**: Pure methods with predictable outputs
5. **Reusability**: Methods can be called multiple times without side effects

## Common Patterns

### Presenter Structure
```ruby
class MyPresenter < BasePresenter
  def initialize(data)
    super()
    @data = data
  end

  # Public methods for template
  def formatted_value
    safe_number(@data[:value])
  end

  def status_class
    case @data[:status]
    when :high then 'badge-success'
    when :medium then 'badge-warning'
    else 'badge-danger'
    end
  end

  private

  # Private helper methods
  def calculate_something
    # Implementation
  end
end
```

### Safe Value Handling
```ruby
def safe_percentage(value)
  return "N/A" if value.nil? || value.infinite?
  "#{value.round}%"
end

def safe_number(value)
  return "0" if value.nil?
  format_number(value)
end
```

## Testing

All presenters have comprehensive test coverage in `spec/wttj_metrics/presenters/`:
- Test all public methods
- Test edge cases (nil values, empty data)
- Test CSS class generation
- Test formatting methods

Run tests with:
```bash
bundle exec rspec spec/wttj_metrics/presenters/
```

## CSS Classes Reference

### Status Badges
- `badge-success` - Positive status (green)
- `badge-warning` - Warning status (yellow)
- `badge-danger` - Negative status (red)
- `badge-info` - Informational (blue)
- `badge-secondary` - Neutral (gray)
- `badge-primary` - Default (brand color)

### Completion Classes
- `completion-high` - ≥80% (green progress bar)
- `completion-medium` - 50-79% (yellow progress bar)
- `completion-low` - <50% (red progress bar)

### Scope Change Classes
- `scope-low` - <10% (green badge)
- `scope-medium` - 10-20% (yellow badge)
- `scope-high` - >20% (red badge)
