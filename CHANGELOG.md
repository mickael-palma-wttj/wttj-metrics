# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Scope Change Tracking**: Display scope change per cycle per team in reports
  - Fetches `scopeChange` field from Linear API cycles query
  - Shows scope change percentage in Cycles by Team table with color coding (red for increase, green for decrease)
  - Adds average scope change column to Team Comparison table
  - Includes scope change data in Excel exports
- **Testing Framework**: RSpec with VCR and WebMock for API mocking
  - Spec support folder with shared configuration
  - 4-phase test pattern (Setup, Exercise, Verify, Teardown)
  - `aggregate_failures` for grouped expectations
  - Named subjects for clarity
- **Metrics Module**: Extracted specialized calculators from MetricsCalculator
  - `Metrics::Base` - Template base class with shared methods
  - `Metrics::FlowCalculator` - Cycle time, lead time, throughput, WIP
  - `Metrics::BugCalculator` - Bug counts, resolution times, priority distribution
  - `Metrics::CycleCalculator` - Sprint/cycle metrics with detail builder
  - `Metrics::DistributionCalculator` - Status, priority, type, size, assignee distributions
  - `Metrics::TeamCalculator` - Completion rate, blocked time
  - `Metrics::TimeseriesCollector` - Time-series data for charts
  - `Metrics::TeamStatsCalculator` - Aggregate team statistics
- **APP_ROOT constant**: Global path constant for file references
- **rubocop-rspec**: RSpec-specific linting rules
- **openssl gem**: Explicit SSL/TLS support dependency
- **Team filtering**: Filter badges showing selected teams in report sections

### Changed

- **MetricsCalculator**: Refactored from 500+ lines to ~60 line facade
  - Now delegates to specialized calculator classes
  - Follows Single Responsibility Principle
- **LinearClient**: Replaced HTTParty with Net::HTTP standard library
  - Reduced external dependencies
  - Uses native Ruby HTTP client with SSL support
- **RuboCop Configuration**: Updated to use `plugins` instead of `require`
  - Added relaxed RSpec cop settings for aggregate_failures style
- **CycleParser**: `DEFAULT_TEAMS` now references `ReportGenerator::SELECTED_TEAMS` (single source of truth)
- **Team Configuration**: Added both `ATS` and `Global ATS` to selected teams
  - `ATS` for cycle data
  - `Global ATS` for bugs data

### Fixed

- **csv gem**: Added explicit dependency for Ruby 3.4+ compatibility
- **STATE_CATEGORIES**: Fixed namespace reference in TransitionDataBuilder

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
