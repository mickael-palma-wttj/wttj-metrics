# Services

This directory contains service classes that orchestrate complex workflows and coordinate multiple components. Services implement the **Service Object Pattern** to encapsulate business logic and application workflows.

## Architecture

Services are the top-level orchestrators that:
- Coordinate multiple domain objects (calculators, presenters, clients)
- Implement complete workflows (data fetching, metric collection, report generation)
- Handle cross-cutting concerns (logging, caching, error handling)
- Provide high-level interfaces for CLI commands

## Service Classes

### ReportService

Orchestrates the complete report generation workflow from data fetching to HTML output.

**Responsibilities:**
- Coordinate data fetching from Linear API
- Trigger metric calculations
- Prepare data for presentation
- Generate HTML report
- Handle logging and error reporting

**Usage:**
```ruby
service = ReportService.new(
  days: 90,
  cache_enabled: true,
  output_path: 'tmp/report.html'
)
service.call
```

**Workflow:**
1. Initialize cache (if enabled)
2. Fetch data from Linear via DataFetcher
3. Calculate all metrics via MetricsCollector
4. Aggregate data via TeamMetricsAggregator
5. Generate HTML via ReportGenerator
6. Log summary via MetricsSummaryLogger

### DataFetcher

Fetches all required data from the Linear API with caching support.

**Responsibilities:**
- Initialize Linear API client with cache
- Fetch issues, cycles, team members, workflow states
- Log data counts for transparency
- Return structured data hash

**Usage:**
```ruby
cache = CacheFactory.enabled
logger = Logger.new($stdout)
fetcher = DataFetcher.new(cache, logger)

data = fetcher.call
# => {
#   issues: [...],      # All Linear issues
#   cycles: [...],      # All cycles/sprints
#   team_members: [...],# Team member data
#   workflow_states: [...]  # Workflow state definitions
# }
```

**Logging Output:**
```
📊 Fetching data from Linear...
   📦 Using cached issues_all (5.2h old)
   📦 Using cached cycles (5.2h old)
   🌐 Fetching team_members from API...
   📦 Using cached workflow_states (5.2h old)
✅ Fetched 6034 issues across 125 cycles
```

### MetricsCollector

Collects and calculates all metrics by coordinating various metric calculators.

**Responsibilities:**
- Initialize all metric calculators (Bug, Cycle, Flow, Team, etc.)
- Execute calculations for each metric domain
- Aggregate results into a unified structure
- Handle date range filtering
- Provide structured metric data

**Usage:**
```ruby
collector = MetricsCollector.new(
  issues: issues,
  cycles: cycles,
  workflow_states: workflow_states,
  start_date: 90.days.ago,
  end_date: Date.today
)

metrics = collector.call
# => {
#   bugs: { total: 150, open: 15, mttr: 48, ... },
#   cycles: [{ name: 'Sprint 49', completion: 85, ... }],
#   teams: { 'ATS' => { velocity: 25, ... } },
#   flow: { throughput: {...}, cycle_time: {...} }
# }
```

**Calculators Coordinated:**
- BugCalculator - Bug metrics
- CycleCalculator - Cycle metrics
- TeamCalculator - Team performance
- FlowCalculator - Flow metrics
- DistributionCalculator - Distribution analysis
- TeamStatsCalculator - Team statistics

### TeamMetricsAggregator

Aggregates team-level metrics across all teams and cycles.

**Responsibilities:**
- Group metrics by team
- Calculate team averages and totals
- Compute team comparisons
- Prepare team-level data for presentation

**Usage:**
```ruby
aggregator = TeamMetricsAggregator.new(issues, cycles)
team_data = aggregator.call

# => {
#   'ATS' => {
#     avg_velocity: 25,
#     avg_completion: 82,
#     bug_rate: 8,
#     total_cycles: 12
#   },
#   'Global ATS' => {
#     avg_velocity: 18,
#     avg_completion: 78,
#     bug_rate: 12,
#     total_cycles: 12
#   }
# }
```

### MetricsSummaryLogger

Logs a summary of collected metrics to the console.

**Responsibilities:**
- Format metrics for console display
- Provide high-level overview of collected data
- Log key metrics (total bugs, cycles, teams)
- Show date ranges and data freshness

**Usage:**
```ruby
logger = MetricsSummaryLogger.new(metrics)
logger.call
```

**Output:**
```
📊 Metrics Summary:
   📈 Total Issues: 6034
   🐛 Total Bugs: 150 (15 open)
   🔄 Total Cycles: 125
   👥 Teams: ATS, Global ATS
   📅 Date Range: 2024-09-09 to 2024-12-08 (90 days)
```

### PresenterMapper

Maps raw metric data to appropriate presenter classes.

**Responsibilities:**
- Select correct presenter for each data type
- Instantiate presenters with data
- Handle presenter configuration
- Provide presenter instances to templates

**Usage:**
```ruby
mapper = PresenterMapper.new

# Map bug data to presenter
bug_presenter = mapper.for_bug(bug_data)
# => BugMetricPresenter instance

# Map cycle data to presenter
cycle_presenter = mapper.for_cycle(cycle_data)
# => CyclePresenter instance

# Map team data to presenter
team_presenter = mapper.for_team(team_name, team_data)
# => TeamMetricPresenter instance
```

### DirectoryPreparer

Prepares output directories and ensures they exist before file operations.

**Responsibilities:**
- Create output directories if missing
- Validate directory paths
- Handle permission issues
- Clean old reports (optional)

**Usage:**
```ruby
preparer = DirectoryPreparer.new
preparer.prepare('tmp/reports')
# => Creates tmp/reports/ if it doesn't exist

preparer.prepare_for_file('tmp/reports/report.html')
# => Creates tmp/reports/ directory
```

### CacheFactory

Factory for creating cache instances with different configurations.

**Responsibilities:**
- Create enabled cache instances (FileCache)
- Create disabled cache instances (nil)
- Provide default cache configuration
- Centralize cache creation logic

**Usage:**
```ruby
# Enabled cache (default)
cache = CacheFactory.enabled
# => FileCache instance

# Disabled cache (for fresh data)
cache = CacheFactory.disabled
# => nil

# Default configuration
cache = CacheFactory.default
# => FileCache instance (same as .enabled)
```

## Service Patterns

### Service Object Pattern
```ruby
class MyService
  def initialize(dependencies)
    @dependencies = dependencies
  end

  def call
    # 1. Validate inputs
    # 2. Execute workflow steps
    # 3. Handle errors
    # 4. Return result
  end

  private

  def step_one
    # Implementation
  end

  def step_two
    # Implementation
  end
end
```

### Factory Pattern
```ruby
class MyFactory
  def self.create(type)
    case type
    when :enabled
      EnabledImplementation.new
    when :disabled
      DisabledImplementation.new
    else
      DefaultImplementation.new
    end
  end
end
```

### Orchestration Pattern
```ruby
class OrchestratorService
  def call
    data = fetch_data
    processed = process_data(data)
    result = generate_output(processed)
    log_summary(result)
    result
  end
end
```

## Workflow Examples

### Complete Report Generation
```ruby
# 1. Create cache
cache = CacheFactory.enabled

# 2. Fetch data
fetcher = DataFetcher.new(cache, logger)
data = fetcher.call

# 3. Collect metrics
collector = MetricsCollector.new(
  issues: data[:issues],
  cycles: data[:cycles],
  workflow_states: data[:workflow_states],
  start_date: 90.days.ago,
  end_date: Date.today
)
metrics = collector.call

# 4. Aggregate team data
aggregator = TeamMetricsAggregator.new(data[:issues], data[:cycles])
team_data = aggregator.call

# 5. Generate report
generator = ReportGenerator.new(metrics, team_data)
generator.generate('tmp/report.html')

# 6. Log summary
logger = MetricsSummaryLogger.new(metrics)
logger.call
```

### Data Collection Only
```ruby
# Without cache
cache = CacheFactory.disabled
fetcher = DataFetcher.new(cache, logger)
data = fetcher.call

# Collect and log
collector = MetricsCollector.new(**data)
metrics = collector.call
MetricsSummaryLogger.new(metrics).call
```

## Design Principles

1. **Single Responsibility**: Each service handles one workflow
2. **Dependency Injection**: Services receive dependencies (don't create them)
3. **Composition**: Services compose other objects to accomplish tasks
4. **Explicit Dependencies**: All dependencies are constructor parameters
5. **Testability**: Services are easy to test with mocked dependencies
6. **Logging**: Services provide visibility into their operations
7. **Error Handling**: Services handle errors gracefully

## Service Responsibilities Matrix

| Service | Data Fetching | Calculations | Formatting | I/O | Logging |
|---------|--------------|--------------|------------|-----|---------|
| ReportService | ✓ (delegates) | ✓ (delegates) | ✓ (delegates) | ✓ | ✓ |
| DataFetcher | ✓ | - | - | - | ✓ |
| MetricsCollector | - | ✓ (delegates) | - | - | - |
| TeamMetricsAggregator | - | ✓ | - | - | - |
| MetricsSummaryLogger | - | - | ✓ | ✓ | ✓ |
| PresenterMapper | - | - | ✓ (delegates) | - | - |
| DirectoryPreparer | - | - | - | ✓ | - |
| CacheFactory | - | - | - | - | - |

## Testing

All services have comprehensive test coverage:
- `spec/wttj_metrics/services/report_service_spec.rb`
- `spec/wttj_metrics/services/data_fetcher_spec.rb`
- `spec/wttj_metrics/services/metrics_collector_spec.rb`
- `spec/wttj_metrics/services/team_metrics_aggregator_spec.rb`
- `spec/wttj_metrics/services/metrics_summary_logger_spec.rb`
- `spec/wttj_metrics/services/presenter_mapper_spec.rb`
- `spec/wttj_metrics/services/directory_preparer_spec.rb`
- `spec/wttj_metrics/services/cache_factory_spec.rb`

Run tests:
```bash
bundle exec rspec spec/wttj_metrics/services/
```

## Dependencies

**Internal:**
- `Sources::Linear::Client` - API client
- `Data::FileCache` - Caching
- All Calculators - Metric calculations
- All Presenters - Data formatting
- `Reports::ReportGenerator` - Report generation

**External:**
- `logger` - Ruby standard library

## Integration Points

**Used By:**
- `CLI` - All commands use services
- `ReportGenerator` - Uses services for data preparation

**Uses:**
- Linear API Client
- All Calculators
- All Presenters
- File Cache
- Report Generator

## Error Handling

Services handle common errors:

```ruby
class MyService
  def call
    validate_inputs!
    execute_workflow
  rescue NetworkError => e
    log_error("Network issue: #{e.message}")
    raise
  rescue ValidationError => e
    log_error("Invalid data: #{e.message}")
    raise
  end

  private

  def validate_inputs!
    raise ValidationError, "Missing data" if @data.nil?
  end
end
```

## Performance Considerations

- **Caching**: Use CacheFactory.enabled for faster data access
- **Parallel Processing**: Services run sequentially (consider parallelization for large datasets)
- **Memory**: Services hold data in memory (consider streaming for huge datasets)
- **Logging**: Excessive logging can slow down operations

## Best Practices

1. **Keep Services Thin**: Delegate to domain objects, don't implement business logic
2. **Use Dependency Injection**: Pass dependencies in constructor
3. **Log Important Events**: Provide visibility into workflow
4. **Handle Errors Gracefully**: Catch and report errors appropriately
5. **Return Consistent Results**: Always return expected data structure
6. **Test with Mocks**: Mock dependencies for fast, isolated tests
7. **Single Call Method**: Services should have one public `call` method
