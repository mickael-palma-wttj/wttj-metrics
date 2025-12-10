# Linear Timeseries Metrics

This module calculates timeseries metrics from Linear issues, tracking daily statistics for tickets, bugs, and state transitions.

## Architecture

Following the composition pattern used in the GitHub timeseries implementation, the Linear timeseries metrics are organized into specialized classes:

### Main Calculator

**`TimeseriesCalculator`** - Orchestrates all timeseries metric calculations
- Processes issues once and delegates to specialized metric classes
- Aggregates results from all metric classes
- Returns rows in format: `[date, category, metric_name, value]`

### Metric Classes

**`Timeseries::TicketMetrics`** - Tracks ticket creation and completion
- Metrics per date:
  - `tickets_created` - Total tickets created
  - `tickets_completed` - Total tickets completed
  - `tickets_created_{team}` - Tickets created by team
  - `tickets_completed_{team}` - Tickets completed by team

**`Timeseries::BugMetrics`** - Tracks bug-specific metrics
- Timeseries metrics per date:
  - `bugs_created` - Total bugs created
  - `bugs_closed` - Total bugs closed
  - `bugs_created_{team}` - Bugs created by team
  - `bugs_closed_{team}` - Bugs closed by team
- Aggregate team statistics:
  - `{team}:created` - Total bugs created by team
  - `{team}:closed` - Total bugs closed by team
  - `{team}:open` - Currently open bugs by team
  - `{team}:mttr` - Mean Time To Resolve (MTTR) in days

**`Timeseries::TransitionMetrics`** - Tracks state transitions
- Metrics per date:
  - `{state}` - Count of transitions to this state
  - `{team}:{state}` - Count of transitions by team

## Design Principles Applied

### Single Responsibility Principle (SRP)
Each class has one clear responsibility:
- `TicketMetrics` - Ticket tracking
- `BugMetrics` - Bug tracking and MTTR calculation
- `TransitionMetrics` - State transition tracking
- `TimeseriesCalculator` - Orchestration and aggregation

### Don't Repeat Yourself (DRY)
- Date-based grouping logic is centralized in each metric class
- Team extraction logic (`team.dig('team', 'name') || 'Unknown'`) is reused
- Bug detection logic is encapsulated in `BugMetrics#issue_is_bug?`

### Composition Over Inheritance
- Metric classes are composed within the calculator
- Each class can be tested independently
- Easy to add new metric types without modifying existing classes

### Data-Driven Design
- Metrics are tracked using hash structures indexed by date
- Enables efficient aggregation and flexible querying
- Supports both daily timeseries and aggregate statistics

## Usage

```ruby
calculator = TimeseriesCalculator.new(issues, today: Date.today)
rows = calculator.to_rows

# Returns array of rows like:
# ["2024-12-01", "timeseries", "tickets_created", 15]
# ["2024-12-01", "timeseries", "bugs_closed_Platform", 3]
# ["2024-12-05", "bugs_by_team", "ATS:mttr", 2.5]
```

## Comparison with GitHub Implementation

| Aspect | GitHub | Linear |
|--------|--------|--------|
| **Structure** | Separate classes per metric type | Separate classes per metric type |
| **Aggregation** | `DailyStats` coordinates metrics | `TimeseriesCalculator` processes directly |
| **Date Handling** | Records on single date (PR creation/merge) | Records on multiple dates (creation/completion/transitions) |
| **Team Metrics** | Limited team tracking | Extensive team-based breakdowns |
| **Special Metrics** | Release tracking | Bug MTTR tracking |

## Testing

Tests are located in `spec/wttj_metrics/metrics/linear/timeseries_collector_spec.rb`

Coverage includes:
- Ticket creation and completion tracking
- Bug identification and metrics
- Team-specific breakdowns
- State transition tracking
- Edge cases (missing team names, no issues)
