# Reports

This directory contains classes responsible for report generation, data aggregation, and chart data preparation. These classes orchestrate the transformation of raw metrics into formatted HTML and Excel reports.

## Architecture

The reports layer consists of:
- **ReportGenerator**: Main orchestrator that coordinates all report generation
- **HtmlGenerator**: Renders HTML reports using ERB templates
- **MetricAccessor**: Provides cached access to parsed metrics with memoization
- **TeamFilter**: Handles team filtering and discovery logic
- **BugsByTeamBuilder**: Aggregates bug statistics by team
- **WeeklyBugFlowBuilder**: Builds weekly bug flow data aggregated by team
- **ChartDataBuilder**: Prepares data for Chart.js visualizations
- **WeeklyDataAggregator**: Aggregates time-series data into weekly buckets
- **ExcelReportBuilder**: Generates Excel reports (alternative output format)

## Classes

### ReportGenerator

The main orchestrator that coordinates data collection, metric calculations, and HTML report generation.

**Responsibilities:**
- Load and parse metrics from CSV files
- Calculate all metrics (bugs, cycles, teams, flow)
- Prepare data for presenters
- Generate chart data for visualizations
- Render HTML report from ERB template
- Write final report to file

**Key Methods:**
```ruby
generator = ReportGenerator.new('tmp/metrics.csv', days: 90)

# Generate complete report
generator.generate('tmp/report.html')
# => Creates comprehensive HTML report with all sections
```

**Data Flow:**
```
CSV File → CsvParser → Metrics Calculators → Presenters → ERB Template → HTML Report
```

**Generated Sections:**
1. Overview metrics (total issues, cycles, teams)
2. Cycle metrics with scope change and completion
3. Team comparison metrics
4. Bug tracking metrics
5. All charts (scatter, bar, line, pie)

**Configuration:**
- `days` - Number of days to include in the report (default: 90)
- Input: CSV file path with metrics
- Output: HTML file path for the report

### MetricAccessor

Provides cached access to parsed metrics with automatic memoization.

**Responsibilities:**
- Retrieve metrics from CSV parser
- Memoize metric results to avoid repeated parsing
- Provide clean interface for metric access

**Key Methods:**
```ruby
accessor = MetricAccessor.new(parser)

# Access various metrics (all memoized)
accessor.flow_metrics          # => Flow metrics array
accessor.cycle_metrics         # => Cycle metrics array
accessor.team_metrics          # => Team metrics array
accessor.bug_metrics           # => Bug metrics array
accessor.bugs_by_priority      # => Bug priority distribution
accessor.status_dist           # => Status distribution
accessor.priority_dist         # => Priority distribution
accessor.type_dist             # => Type distribution
accessor.assignee_dist         # => Top 15 assignees by count
```

**Benefits:**
- **Performance**: Each metric type fetched only once
- **Clean Interface**: Single object for all metric access
- **Separation of Concerns**: Parsing logic separate from usage

### TeamFilter

Handles team filtering and discovery logic for reports.

**Responsibilities:**
- Resolve team selection (all teams, default teams, or custom list)
- Discover all teams from metrics data
- Provide team filtering logic

**Key Methods:**
```ruby
# Use default teams
filter = TeamFilter.new(parser)
filter.selected_teams  # => ['ATS', 'Global ATS', 'Marketplace', ...]

# Discover all teams
filter = TeamFilter.new(parser, teams: :all)
filter.selected_teams  # => ['ATS', 'Global ATS', 'Platform', 'ROI', ...]
filter.all_teams_mode?  # => true

# Custom team list
filter = TeamFilter.new(parser, teams: ['ATS', 'Platform'])
filter.selected_teams  # => ['ATS', 'Platform']
```

**Features:**
- Automatic team discovery from bug metrics
- Default team configuration
- Custom team filtering
- Excludes 'Unknown' and nil teams

### BugsByTeamBuilder

Builds aggregated bug statistics by team from raw metrics.

**Responsibilities:**
- Parse bug metrics by team
- Aggregate bug statistics (created, closed, open, MTTR)
- Filter by selected teams
- Sort teams by open bug count

**Key Methods:**
```ruby
builder = BugsByTeamBuilder.new(parser, selected_teams)
bugs_by_team = builder.build

# Returns hash like:
# {
#   'ATS' => { created: 45, closed: 38, open: 7, mttr: 48 },
#   'Platform' => { created: 32, closed: 30, open: 2, mttr: 36 },
#   ...
# }
```

**Features:**
- Automatic metric parsing from "Team:stat" format
- MTTR values rounded to integers
- Sorted by open bugs (descending)
- Only includes selected teams

### ChartDataBuilder

Transforms raw metrics into Chart.js-compatible data structures for visualizations.

**Responsibilities:**
- Group status data into logical categories
- Sort and filter chart data
- Format data for specific chart types (pie, bar, scatter, line)
- Apply color schemes and styling
- Handle empty or missing data gracefully

**Key Methods:**
```ruby
builder = ChartDataBuilder.new(metrics_parser)

# Status distribution (pie chart)
status_data = builder.status_chart_data
# => [
#   { label: 'Backlog', value: 50, breakdown: [...] },
#   { label: 'In Progress', value: 30, breakdown: [...] },
#   ...
# ]

# Priority distribution (bar chart)
priority_data = builder.priority_chart_data
# => [
#   { label: 'Urgent', value: 10 },
#   { label: 'High', value: 25 },
#   ...
# ]

# Scope change vs completion (scatter chart)
scatter_data = builder.scope_vs_completion_data
# => [
#   { x: 15, y: 85, team: 'ATS', cycle: 'Sprint 49' },
#   ...
# ]
```

**Status Groups:**
- **Backlog**: Backlog, Triage, Archived
- **To Do**: Todo, To Do, To design, To dev, To Qualify
- **In Progress**: In Progress, In progress
- **In Review**: In Review, To Review, To test, To Validate, To Merge
- **Done**: Done, Released, Canceled, Duplicate, Auto-closed

**Priority Order:**
- Urgent → High → Medium → Low

**Chart Types Supported:**
1. **Pie Charts**: Status distribution, priority distribution
2. **Bar Charts**: Bugs by team, bugs by priority
3. **Scatter Charts**: Scope change vs completion
4. **Line Charts**: Bug flow over time, weekly trends

### WeeklyDataAggregator

Aggregates time-series metrics into weekly buckets with percentage calculations.

**Responsibilities:**
- Group daily metrics by week (Monday-Sunday)
- Calculate week-over-week percentages
- Handle paired metrics (e.g., opened vs closed)
- Handle single metrics (e.g., total count)
- Format data for line charts

**Key Methods:**
```ruby
aggregator = WeeklyDataAggregator.new(cutoff_date: Date.today)

# Aggregate two metrics for comparison
result = aggregator.aggregate_pair(
  bugs_opened_data,
  bugs_closed_data,
  labels: [:opened, :closed]
)
# => {
#   labels: ['2024-W49', '2024-W50', '2024-W51'],
#   opened: [10, 15, 12],
#   closed: [8, 14, 11],
#   opened_pct: [56, 52, 52],  # opened / (opened + closed) * 100
#   closed_pct: [44, 48, 48]
# }

# Aggregate single metric
result = aggregator.aggregate_single(bugs_total_data)
# => {
#   labels: ['2024-W49', '2024-W50', '2024-W51'],
#   values: [100, 110, 115]
# }
```

**Features:**
- Week-based grouping (ISO 8601 weeks)
- Percentage calculation for paired metrics
- Automatic label generation (YYYY-Wnn format)
- Cutoff date handling (excludes future weeks)
- Zero-value handling for missing data

**Use Cases:**
- Bug flow charts (opened vs closed per week)
- Velocity trends (issues completed per week)
- Throughput analysis (work items by week)
- Cycle time trends over weeks

### ExcelReportBuilder

Generates Excel reports as an alternative to HTML reports (future implementation).

**Responsibilities:**
- Create Excel workbooks with multiple sheets
- Format cells with colors and styles
- Generate Excel charts
- Export metrics in spreadsheet format

**Planned Features:**
- Multiple sheets (Overview, Cycles, Teams, Bugs)
- Conditional formatting (red/yellow/green for metrics)
- Pivot tables for data analysis
- Excel charts (equivalent to HTML charts)

**Usage (planned):**
```ruby
builder = ExcelReportBuilder.new(metrics_data)
builder.generate('tmp/report.xlsx')
```

## Data Flow

```
1. CSV Metrics File
   ↓
2. CsvParser.new(csv_path)
   ↓
3. ChartDataBuilder.new(parser)
   ↓
4. WeeklyDataAggregator.new(cutoff_date)
   ↓
5. ReportGenerator orchestrates:
   - Calls calculators for all metrics
   - Calls ChartDataBuilder for chart data
   - Calls WeeklyDataAggregator for time-series
   - Passes data to presenters
   - Renders ERB template
   ↓
6. HTML Report File (tmp/report.html)
```

## Report Structure

### HTML Report Sections

1. **Header**
   - Report title
   - Date range
   - Generation timestamp

2. **Overview**
   - Total issues
   - Total cycles
   - Total teams
   - Date range summary

3. **Cycle Metrics**
   - Cycles by Team table
   - Scope Change vs Completion chart
   - Cycles Timeline chart

4. **Team Comparison**
   - Team Metrics table
## File Organization

```
reports/
├── README.md                    # This file
├── report_generator.rb          # Main orchestrator
├── metric_accessor.rb           # Memoized metric access
├── team_filter.rb               # Team selection logic
├── bugs_by_team_builder.rb      # Bug aggregation by team
├── chart_data_builder.rb        # Chart data preparation
├── weekly_data_aggregator.rb    # Weekly time-series aggregation
└── excel_report_builder.rb      # Excel report generation
```

## Design Principles

1. **Single Responsibility**: Each class handles one aspect of report generation
2. **Separation of Concerns**: Data access, filtering, aggregation, and rendering are separate
3. **Memoization**: Expensive operations cached automatically
4. **Composition**: Small, focused classes composed together
5. **Clean Interfaces**: Simple, intention-revealing method names

## Dependencies

**Internal:**
- `Data::CsvParser` - Reading metrics from CSV
- `Metrics::*Calculator` - Calculating metrics
- `Presenters::*Presenter` - Formatting for display
- `Helpers::*Helper` - Utility functions

**External:**
- `erb` - ERB template rendering
- `json` - JSON serialization for chart data
- `date` - Date manipulation

1. **Orchestration**: ReportGenerator coordinates all report generation steps
2. **Data Transformation**: Builders transform raw data into display-ready formats
3. **Separation of Concerns**: Each class has a specific transformation responsibility
4. **Configurability**: Reports can be generated for different time periods
5. **Extensibility**: Easy to add new charts or report sections

## Common Patterns

### Report Generation Pattern
```ruby
# 1. Parse metrics
parser = CsvParser.new('tmp/metrics.csv')

# 2. Build chart data
chart_builder = ChartDataBuilder.new(parser)
charts = {
  status: chart_builder.status_chart_data,
  priority: chart_builder.priority_chart_data,
  scatter: chart_builder.scope_vs_completion_data
}

# 3. Aggregate weekly data
aggregator = WeeklyDataAggregator.new(cutoff_date: Date.today)
weekly = aggregator.aggregate_pair(opened_data, closed_data)

# 4. Generate report
generator = ReportGenerator.new('tmp/metrics.csv', days: 90)
generator.generate('tmp/report.html')
```

### HtmlGenerator

Handles HTML report generation using ERB templates.

**Responsibilities:**
- Render ERB templates with report data
- Generate fallback HTML when template is missing
- Write HTML content to files

**Key Methods:**
```ruby
generator = HtmlGenerator.new(report_generator)

# Generate and write HTML
generator.generate('tmp/report.html')
# => Writes rendered HTML to file

# Build HTML content
html = generator.build_html
# => Returns HTML string
```

**Benefits:**
- **Separation**: HTML rendering isolated from data preparation
- **Testability**: Template rendering can be tested independently
- **Flexibility**: Easy to add alternative template formats

### WeeklyBugFlowBuilder

Builds weekly bug flow data aggregated by team.

**Responsibilities:**
- Aggregate bug creation/closure data by week
- Group data by team for team-specific charts
- Calculate week labels and counts

**Key Methods:**
```ruby
builder = WeeklyBugFlowBuilder.new(parser, selected_teams, cutoff_date)

# Build overall bug flow data
flow_data = builder.build_flow_data
# => { labels: [...], created: [...], closed: [...], created_pct: [...], closed_pct: [...] }

# Build team-specific bug flow data
team_data = builder.build_by_team_data(flow_data[:labels])
# => { labels: [...], teams: { 'ATS' => { created: [...], closed: [] }, ... } }
```

**Benefits:**
- **Focus**: Single responsibility for bug flow aggregation
- **Reusability**: Can be used for different time ranges
- **Clarity**: Clear separation from general report logic

### Chart Data Format
```ruby
# For Chart.js consumption
{
  labels: ['Label 1', 'Label 2', 'Label 3'],
  datasets: [{
    label: 'Dataset Name',
    data: [10, 20, 30],
    backgroundColor: ['#ff0000', '#00ff00', '#0000ff']
  }]
}
```

## Performance Considerations

### Report Generation Speed
- CSV parsing: Fast (<100ms for typical files)
- Metric calculations: Moderate (1-2s for 6000 issues)
- Chart data building: Fast (<200ms)
- ERB rendering: Fast (<100ms)
- **Total**: ~2-3 seconds for full report generation

### Memory Usage
- Parser holds all metrics in memory (~10-50 MB)
- Chart data is relatively small (~1-5 MB)
- ERB template rendering creates temporary strings
- **Peak**: ~50-100 MB during generation

### Optimization Tips
1. Use `days` parameter to limit data scope
2. Cache API responses to avoid refetching
3. Pre-filter issues before passing to calculators
4. Reuse parser instance for multiple operations

## File Organization

```
lib/wttj_metrics/reports/
├── bugs_by_team_builder.rb       # Bug statistics aggregation by team
├── chart_data_builder.rb         # Chart.js data preparation
├── excel_report_builder.rb       # Excel report generation
├── html_generator.rb             # HTML rendering with ERB templates
├── metric_accessor.rb            # Cached metric access
├── report_generator.rb           # Main orchestrator (294 lines, 34 methods)
├── team_filter.rb                # Team filtering and discovery
├── weekly_bug_flow_builder.rb    # Weekly bug flow aggregation
└── weekly_data_aggregator.rb     # Time-series weekly aggregation
```

## Testing

All report classes have test coverage:
- `spec/wttj_metrics/reports/report_generator_spec.rb`
- `spec/wttj_metrics/reports/html_generator_spec.rb`
- `spec/wttj_metrics/reports/metric_accessor_spec.rb`
- `spec/wttj_metrics/reports/team_filter_spec.rb`
- `spec/wttj_metrics/reports/bugs_by_team_builder_spec.rb`
- `spec/wttj_metrics/reports/weekly_bug_flow_builder_spec.rb`
- `spec/wttj_metrics/reports/chart_data_builder_spec.rb`
- `spec/wttj_metrics/reports/weekly_data_aggregator_spec.rb`
- `spec/wttj_metrics/reports/excel_report_builder_spec.rb`

Run tests:
```bash
bundle exec rspec spec/wttj_metrics/reports/
```

## Dependencies

**Internal:**
- `Data::CsvParser` - Reading metrics from CSV
- `Metrics::*Calculator` - Calculating metrics
- `Presenters::*Presenter` - Formatting for display
- `Helpers::*Helper` - Utility functions

**External:**
- `erb` - ERB template rendering
- `json` - JSON serialization for chart data
- `date` - Date manipulation

## Integration Points

**Used By:**
- `CLI` - `report` command calls ReportGenerator
- `Services::ReportService` - High-level report generation orchestration

**Uses:**
- All Calculators (Bug, Cycle, Team, Flow, etc.)
- All Presenters (Bug, Cycle, Team, etc.)
- All Helpers (Date, Formatting, Issue)
- Templates (report.html.erb)

## Output Examples

### HTML Report
- Location: `tmp/report.html` or custom path
- Size: ~500 KB - 2 MB (includes inline CSS and Chart.js)
- Format: Self-contained HTML (no external dependencies except Chart.js CDN)

### Console Output During Generation
```
📊 Generating report for last 90 days...
   📄 Parsing metrics from tmp/metrics.csv
   📈 Building chart data...
   📊 Calculating metrics...
   ✏️  Rendering report template...
   💾 Writing report to tmp/report.html
✅ Report generated successfully!
```
