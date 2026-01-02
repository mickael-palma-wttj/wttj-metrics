# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Date Range Filtering**: New `--start-date` and `--end-date` CLI options for both `collect` and `report` commands
  - Specify exact date ranges in YYYY-MM-DD format (e.g., `--start-date 2024-01-01 --end-date 2024-06-30`)
  - End date is inclusive (includes all items from that day)
  - Overrides `--days` when provided; `--days` still works as before
  - Filters Linear issues by creation date and cycles by overlap with date range
  - Filters GitHub PRs by creation date
  - Report generation respects date range for chart display and header text
- **Percentile Charts for Linear Reports**: New statistical visualizations integrated into existing report sections
  - **Bug Tracking Section**: Bug MTTR by Team bar chart showing mean time to resolve bugs per team
  - **Ticket Flow Section**: Daily Throughput Percentiles (P50/P75/P90/P95) line chart and Weekly Throughput Trend bar chart
  - **Team Comparison Section**: Cycle Velocity Distribution, Completion Rate Distribution, and Completion Rate Histogram
  - New `Reports::Linear::PercentileDataBuilder` class for calculating percentile metrics
- **Percentile Charts for GitHub Reports**: Statistical visualizations for PR and CI metrics
  - **Efficiency Trends Section**: Time to First Review (P50/P75/P90/P95) and Time to Merge (P50/P75/P90/P95) line charts
  - **Quality & Health Section**: PR Size Distribution histogram, CI Time to Green percentiles, and CI Success Rate Distribution
  - **Collaboration Section**: Weekly PR Throughput trend chart
  - New `Reports::GitHub::PercentileDataBuilder` class for calculating GitHub percentile metrics
- **Team Configuration System**: New configuration file support (`lib/config/teams.yml`) to map logical teams to source-specific names
  - Supports 1-to-many mapping (e.g., one Linear team to multiple GitHub teams)
  - Wildcard support for team matching
  - New CLI option `--teams-config` to specify custom configuration path
- **GitHub Team Metrics**: Detailed team-level breakdown in GitHub HTML report
  - Sortable and filterable table for team metrics
  - Zebra striping and visual indicators for better readability
  - Metrics include: Merge Rate, Time to Merge, Review Velocity, and more
- **Commit Activity Heatmap**: Visual heatmap showing commit frequency by day of week and hour
  - Helps identify peak coding hours and team work patterns

### Refactored

- **GitHub Metrics Architecture**: Split monolithic calculator into specialized classes
  - `PrVelocityCalculator`, `QualityCalculator`, `CollaborationCalculator`, etc.
  - Improved testability and separation of concerns
- **View Logic**: Extracted formatting logic to `FormattingHelper`
  - Centralized number formatting and color coding logic
- **Report Generation**: Refactored `ReportGenerator` to use `TeamService` and `MetricsCalculator`

### Refactored

- **Linear Reports Architecture**: Major refactoring of the Linear reporting module
  - **Namespace Consolidation**: Moved all Linear-specific reporting classes to `WttjMetrics::Reports::Linear` namespace
    - `MetricAccessor` → `Linear::MetricAccessor`
    - `TeamFilter` → `Linear::TeamFilter`
    - `BugsByTeamBuilder` → `Linear::BugsByTeamBuilder`
    - `WeeklyBugFlowBuilder` → `Linear::WeeklyBugFlowBuilder`
    - `WeeklyDataAggregator` → `Linear::WeeklyDataAggregator`
  - **ReportGenerator**: Refactored to use Facade pattern and `Forwardable` for cleaner delegation
  - **Excel Reporting**: Extracted `ExcelFormatter` from `ExcelReportBuilder` for better separation of concerns
  - **Code Quality**: Resolved Reek (LongParameterList) and RuboCop issues across the module

### Added

- **GitHub Metrics Integration**: Full support for GitHub pull request metrics
  - **Data Collection**: Fetches PRs, reviews, comments, and commits via GraphQL API
  - **Key Metrics**: Average Time to Merge, Time to First Review, Reviews/PR, Comments/PR
  - **Repository Activity**: "Top 10 Active Repositories" chart and detailed breakdown
  - **Daily Breakdown**: Created, Merged, Closed, and Open PRs over time
  - **Excel Export**: Dedicated sheets for GitHub metrics and repository activity
  - **Caching**: Efficient caching of GitHub data to minimize API calls
  - **Error Handling**: Robust handling of rate limits, timeouts, and authentication errors
- **Average Review Time Metric**: New metric in Key Metrics section showing average time spent in review states
  - Calculates time in states matching "review", "validate", "test", or "merge"
  - Displayed as days with tooltip explanation
  - Added to FlowCalculator with proper calculation logic
- **Mean Time To Resolve (MTTR)**: New metric for bugs by team
  - Tracks resolution time for closed bugs by team
  - Displayed in "Bug Stats by Team (All Time)" table
  - Added to TimeseriesCollector and BugTeamPresenter
- **Enhanced Issue Type Classification**: Improved from 4 to 7 categories
  - New categories: Feature, Bug, Improvement, Tech Debt, Task, Documentation, Other
  - Title-based fallback classification when labels are missing
  - Pattern matching with regex for accurate categorization
  - Reduced "Other" classification from 88% to 73%
- **Comprehensive Service Specs**: 96 service object tests (71 new tests)
  - `CacheFactory` specs (8 tests) - cache instantiation
  - `DirectoryPreparer` specs (8 tests) - directory creation
  - `DataFetcher` specs (12 tests) - Linear API integration
  - `MetricsSummaryLogger` specs (11 tests) - summary logging
  - `MetricsCollector` specs (16 tests) - collection workflow
  - `ReportService` specs (16 tests) - report generation
  - `TeamMetricsAggregator` specs (10 tests) - metrics aggregation
  - `PresenterMapper` specs (15 tests) - presenter instantiation
- **E2E Testing Framework**: Playwright tests for HTML reports
  - 77 e2e tests covering accessibility, charts, mobile, data integrity
  - Visual regression testing with snapshots
  - Cross-browser testing support
- **Service Objects**: Additional report generation services
  - `Services::TeamMetricsAggregator` - Aggregates team timeseries metrics
  - `Services::PresenterMapper` - Maps data to presenter objects (DRY presenter instantiation)
- **Testing Framework**: RSpec with VCR and WebMock for API mocking
  - Spec support folder with shared configuration
  - 4-phase test pattern (Setup, Exercise, Verify, Teardown)
  - `aggregate_failures` for grouped expectations
  - Named subjects for clarity
  - 485 test examples with 66.08% branch coverage, 87.76% line coverage
- **Metrics Module**: Extracted specialized calculators from MetricsCalculator
  - `Metrics::Base` - Template base class with shared methods
  - `Metrics::FlowCalculator` - Cycle time, lead time, throughput, WIP
  - `Metrics::BugCalculator` - Bug counts, resolution times, priority distribution
  - `Metrics::CycleCalculator` - Sprint/cycle metrics with detail builder
  - `Metrics::DistributionCalculator` - Status, priority, type, size, assignee distributions
  - `Metrics::TeamCalculator` - Completion rate, blocked time
  - `Metrics::TimeseriesCollector` - Time-series data for charts
  - `Metrics::TeamStatsCalculator` - Aggregate team statistics
- **Service Objects**: Extracted CLI business logic following SRP and Sandi Metz rules
  - `Services::MetricsCollector` - Orchestrates metrics collection workflow
  - `Services::DataFetcher` - Handles Linear API data fetching
  - `Services::MetricsSummaryLogger` - Formats and displays metrics summary
  - `Services::DirectoryPreparer` - Ensures output directories exist
  - `Services::ReportService` - Generates HTML and Excel reports
  - `Services::CacheFactory` - Centralizes cache instantiation
  - `Services::TeamMetricsAggregator` - Aggregates team metrics by date
  - `Services::PresenterMapper` - DRY presenter object instantiation
- **Value Objects**: Encapsulate command options
  - `Values::CollectOptions` - Collect command options with cache strategy
  - `Values::ReportOptions` - Report command options with team filtering
- **Logger Infrastructure**:
  - `Helpers::LoggerMixin` - Shared logger configuration across CLI classes
  - Structured logging with custom formatter (removes timestamps for clean CLI output)
  - Test output redirected to `tmp/test.log` for clean test runs
- **VSCode Debugging**: RSpec debugging configurations in `.vscode/launch.json`
- **APP_ROOT constant**: Global path constant for file references
- **rubocop-rspec**: RSpec-specific linting rules
- **openssl gem**: Explicit SSL/TLS support dependency
### Changed

- **FlowCalculator**: Applied DRY refactoring
  - Extracted `average_duration` and `average_from_collection` helpers
  - Added constants: DAYS_IN_WEEK, REVIEW_STATE_PATTERN, AVERAGE_PRECISION
  - Introduced template method pattern for `calculate_state_durations`
- **ReportGenerator**: Major refactoring (479→464 lines)
  - Extracted 15+ helper methods for improved readability
  - Removed require_relative statements (Zeitwerk autoloading)
  - Uses TeamMetricsAggregator and PresenterMapper service objects
  - Simplified discover_all_teams with functional chain
- **DistributionCalculator**: Enhanced type classification
  - Expanded from 4 to 7 issue type categories
  - Added title-based pattern matching as fallback
  - Pattern methods: bug_pattern?, feature_pattern?, improvement_pattern?, etc.
  - Title methods: title_indicates_bug?, title_indicates_feature?, etc.
- **Chart Colors**: Updated type distribution pie chart for 7 categories
- **MetricsCalculator**: Refactored from 500+ lines to ~60 line facade
  - Now delegates to specialized calculator classes
  - Follows Single Responsibility Principle0+ lines to ~60 line facade
  - Now delegates to specialized calculator classes
  - Follows Single Responsibility Principle
- **CLI**: Major refactoring from 123 lines to 67 lines
  - All methods now under 10 lines (Sandi Metz rules)
  - Replaced `puts` with structured Logger
  - Extracted business logic to service objects
  - `collect` method reduced from 33 lines to 3 lines
  - `report` method reduced from 18 lines to 3 lines
- **LinearClient**: Replaced HTTParty with Net::HTTP standard library
  - Reduced external dependencies
  - Uses native Ruby HTTP client with SSL support
- **FileCache**: Migrated from `puts` to Logger for structured output
- **ReportGenerator**: Migrated from `puts` to Logger for structured output
- **RuboCop Configuration**: Updated to use `plugins` instead of `require`
  - Added relaxed RSpec cop settings for aggregate_failures style
  - Increased limits: MultipleExpectations (15), ExampleLength (25), MultipleMemoizedHelpers (15)
- **CycleParser**: `DEFAULT_TEAMS` now references `ReportGenerator::SELECTED_TEAMS` (single source of truth)
- **Team Configuration**: Added both `ATS` and `Global ATS` to selected teams
  - `ATS` for cycle data
  - `Global ATS` for bugs data

### Refactored

- **Architecture**: Applied Ruby best practices and design patterns
### Fixed

- **E2E Tests**: Updated key metrics count from 9 to 10 in Playwright tests
- **RuboCop**: Disabled RSpec/VerifiedDoubles cop (acceptable for simple value objects)
- **Bug Pattern**: Added "hotfix" label to bug classification regex
- **Line Length**: Fixed RuboCop violations with multi-line regex patterns
- **csv gem**: Added explicit dependency for Ruby 3.4+ compatibilityr method names
  - **Sandi Metz Rules**: All methods <10 lines, classes <100 lines, <4 parameters
  - **Service Object Pattern**: Business logic extracted from CLI into dedicated services
  - **Value Object Pattern**: Options encapsulated, eliminated hash drilling
  - **Factory Method Pattern**: Centralized cache instantiation
  - **Mixin Pattern**: Shared logger behavior via `Helpers::LoggerMixin`
  - **Command Pattern**: Unified `.call` interface for services
  - **Tell Don't Ask**: Objects handle their own logic
  - **Law of Demeter**: Reduced coupling through value objects
- **Code Organization**: Proper namespace hierarchy
  - `WttjMetrics::Helpers::` for mixins and view helpers
  - `WttjMetrics::Services::` for business logic services
  - `WttjMetrics::Values::` for value objects
  - Follows Zeitwerk autoloading conventions

### Fixed

- **csv gem**: Added explicit dependency for Ruby 3.4+ compatibility
- **STATE_CATEGORIES**: Fixed namespace reference in TransitionDataBuilder
- **CI Compatibility**: `tmp` directory auto-created during test runs
  - Prevents failures in CI environments where tmp doesn't exist
  - Test logger output properly redirected

## [0.1.0] - 2024-12-01

### Added

- Initial release
- Linear API integration for fetching issues, cycles, and workflow states
- HTML dashboard with Chart.js visualizations
- Excel report export with caxlsx
- CLI with Thor (collect, report, cache commands)
- Team filtering for reports
- API response caching
- WTTJ branding and styling
