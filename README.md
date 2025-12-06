# WTTJ Metrics

A Ruby CLI tool to collect metrics from [Linear](https://linear.app) and generate beautiful HTML/Excel reports. Built for Welcome to the Jungle engineering teams.

![Ruby](https://img.shields.io/badge/Ruby-3.2+-red?logo=ruby)
![License](https://img.shields.io/badge/License-MIT-blue)
[![CI](https://github.com/mickael-palma-wttj/wttj-metrics/actions/workflows/ci.yml/badge.svg)](https://github.com/mickael-palma-wttj/wttj-metrics/actions/workflows/ci.yml)

---

## Table of Contents

- [Features](#features)
- [Dashboard Overview](#dashboard-overview)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
  - [Collecting Metrics](#collecting-metrics)
  - [Generating Reports](#generating-reports)
  - [Cache Management](#cache-management)
  - [Full Workflow Example](#full-workflow-example)
- [Configuration](#configuration)
  - [Environment Variables](#environment-variables)
  - [Team Filtering](#team-filtering)
  - [Customizing Default Teams](#customizing-default-teams)
- [Metrics Reference](#metrics-reference)
  - [Flow Metrics](#flow-metrics)
  - [Bug Metrics](#bug-metrics)
  - [Cycle/Sprint Metrics](#cyclesprint-metrics)
  - [Distribution Metrics](#distribution-metrics)
- [Architecture](#architecture)
  - [System Overview](#system-overview)
  - [Project Structure](#project-structure)
  - [Key Components](#key-components)
  - [Data Flow](#data-flow)
- [Linear API Integration](#linear-api-integration)
  - [Required Permissions](#required-permissions)
  - [GraphQL Queries](#graphql-queries)
  - [Rate Limiting](#rate-limiting)
- [Development](#development)
  - [Prerequisites](#prerequisites)
  - [Dev Container](#dev-container)
  - [Code Style](#code-style)
  - [Testing](#testing)
  - [Running Locally](#running-locally)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Dependencies](#dependencies)
- [Changelog](#changelog)
- [License](#license)

---

## Features

- 📊 **Collect Metrics** - Fetch issues, cycles, and team data from Linear GraphQL API
- 📈 **HTML Dashboard** - Interactive charts with Chart.js (flow, bugs, cycles, distributions)
- 📑 **Excel Export** - Detailed spreadsheets for further analysis
- 🐛 **Bug Tracking** - Track bug creation/resolution by team over time
- ⚡ **Caching** - Smart API response caching for faster subsequent runs
- 🎨 **WTTJ Branding** - Dashboard styled with Welcome to the Jungle colors
- 🔧 **Team Filtering** - Focus reports on specific teams or view all teams
- 📆 **Time Range Selection** - Customize report period (default: 90 days)

---

## Dashboard Overview

The generated HTML dashboard includes the following sections:

| Section | Description |
|---------|-------------|
| **Key Metrics** | Cycle time, lead time, WIP, throughput, completion rate |
| **Bugs** | Open bugs, resolution rate, bugs by priority, bug flow by team |
| **Ticket Flow** | Created vs completed tickets over time, state transitions |
| **Distributions** | Status, priority, type, and assignee breakdowns |
| **Cycles** | Sprint metrics, velocity, commitment accuracy, scope change, team performance |

---

## Quick Start

```bash
# 1. Clone and install
git clone https://github.com/mickael-palma-wttj/wttj-metrics.git
cd wttj-metrics
bundle install

# 2. Configure your Linear API key
echo "LINEAR_API_KEY=lin_api_xxxxxxxxxxxxxxxxxxxxx" > .env

# 3. Collect metrics and generate report
./bin/wttj-metrics collect -o metrics.csv
./bin/wttj-metrics report metrics.csv --excel

# 4. Open the report
open report/report.html
```

---

## Installation

### Prerequisites

- **Ruby 3.2+** (Ruby 3.4 recommended)
- **Bundler** gem
- **Linear API key** ([Get one here](https://linear.app/settings/api))

### Setup

```bash
# Clone the repository
git clone https://github.com/mickael-palma-wttj/wttj-metrics.git
cd wttj-metrics

# Install dependencies
bundle install

# Configure environment
cp .env.example .env
# Or create .env manually
```

Edit `.env` with your Linear credentials:

```bash
LINEAR_API_KEY=lin_api_xxxxxxxxxxxxxxxxxxxxx
```

### Verify Installation

```bash
# Check version
./bin/wttj-metrics version

# Expected output: wttj-metrics v1.0.0
```

---

## Usage

### Collecting Metrics

Fetch data from Linear API and save to CSV:

```bash
# Default output to tmp/metrics.csv
./bin/wttj-metrics collect

# Custom output path
./bin/wttj-metrics collect -o metrics.csv

# Clear cache before fetching
./bin/wttj-metrics collect --clear-cache

# Disable caching entirely
./bin/wttj-metrics collect --no-cache
```

#### Collection Options

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--output` | `-o` | `tmp/metrics.csv` | CSV output file path |
| `--cache` | | `true` | Use cache for API responses |
| `--clear-cache` | | `false` | Clear cache before fetching |

### Generating Reports

Create HTML dashboard from collected metrics:

```bash
# Default: last 90 days, output to report/report.html
./bin/wttj-metrics report metrics.csv

# Custom time range (365 days)
./bin/wttj-metrics report metrics.csv --days 365

# Also generate Excel report
./bin/wttj-metrics report metrics.csv --excel

# Custom output paths
./bin/wttj-metrics report metrics.csv -o dashboard.html --excel-path data.xlsx

# Filter to specific teams
./bin/wttj-metrics report metrics.csv --teams ATS Platform Sourcing

# Show all teams (no filtering)
./bin/wttj-metrics report metrics.csv --all-teams
```

#### Report Options

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--output` | `-o` | `report/report.html` | HTML output file path |
| `--days` | `-d` | `90` | Number of days to show in charts |
| `--teams` | `-t` | *default list* | Teams to include in report |
| `--all-teams` | | `false` | Include all teams (no filter) |
| `--excel` | `-x` | `false` | Also generate Excel spreadsheet |
| `--excel-path` | | `report/report.xlsx` | Excel output file path |

### Cache Management

```bash
# Clear all cached API responses
./bin/wttj-metrics cache clear

# Show cache directory path
./bin/wttj-metrics cache path
```

### Full Workflow Example

```bash
# Collect fresh data and generate comprehensive report
./bin/wttj-metrics collect --clear-cache -o metrics.csv && \
./bin/wttj-metrics report metrics.csv --days 365 --excel --all-teams
```

---

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `LINEAR_API_KEY` | Yes | - | Your Linear API key (starts with `lin_api_`) |
| `CSV_OUTPUT_PATH` | No | `tmp/metrics.csv` | Default CSV output path |

### Team Filtering

By default, the report filters metrics to selected teams. You can control this via CLI options:

```bash
# Use default teams (ATS, Global ATS, Marketplace, Platform, ROI, Sourcing, Talents)
./bin/wttj-metrics report metrics.csv

# Specify custom teams (use quotes for names with spaces)
./bin/wttj-metrics report metrics.csv --teams "Global ATS" Platform Sourcing

# Show all teams from the data (no filtering)
./bin/wttj-metrics report metrics.csv --all-teams
```

> **Note:** Filtered charts display a "Filtered" badge. When using `--all-teams`, all teams from the data are included and no filter badge is shown.

### Customizing Default Teams

To change the default teams, edit `SELECTED_TEAMS` in `lib/wttj_metrics/report_generator.rb`. Check the current defaults in that file as they may change over time.

```ruby
# Example: Current default teams (check report_generator.rb for latest)
SELECTED_TEAMS = ['ATS', 'Global ATS', 'Marketplace', 'Platform', 'ROI', 'Sourcing', 'Talents'].freeze
```

---

## Metrics Reference

### Flow Metrics

| Metric | Formula | Description |
|--------|---------|-------------|
| **Cycle Time** | `completedAt - startedAt` | Time from work started to completed (in days) |
| **Lead Time** | `completedAt - createdAt` | Time from creation to completion (in days) |
| **Throughput** | `count(completed issues) / period` | Issues completed per time period |
| **WIP (Work in Progress)** | `count(in_progress issues)` | Issues currently being worked on |
| **Completion Rate** | `completed / (completed + cancelled) × 100` | Percentage of issues completed vs cancelled |

### Bug Metrics

| Metric | Formula | Description |
|--------|---------|-------------|
| **Open Bugs** | `count(bugs where state != done/cancelled)` | Currently open bug issues |
| **Bug Resolution Time** | `avg(completedAt - createdAt)` for bugs | Average time to resolve bugs |
| **Bug Creation Rate** | `count(bugs created) / period` | Bugs created per time period |
| **Bugs by Priority** | `group_by(priority)` | Distribution of bugs by priority level |
| **Bugs by Team** | `group_by(team)` | Bug counts per team |

### Cycle/Sprint Metrics

| Metric | Formula | Description |
|--------|---------|-------------|
| **Velocity** | `sum(completed estimates)` | Total story points completed in cycle |
| **Commitment Accuracy** | `completed / planned × 100` | How well the team met sprint commitment |
| **Scope Change** | `(final - initial) / initial × 100` | Change in sprint scope during cycle |
| **Completion Rate** | `completed / total × 100` | Percentage of issues completed |

### Distribution Metrics

| Metric | Description |
|--------|-------------|
| **Status Distribution** | Breakdown of issues by workflow state |
| **Priority Distribution** | Issues grouped by priority (Urgent, High, Medium, Low, None) |
| **Type Distribution** | Issues by label/type (Bug, Feature, Improvement, etc.) |
| **Assignee Distribution** | Top 15 assignees by issue count |

---

## Architecture

### System Overview

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Linear     │────▶│ wttj-metrics │────▶│   Reports    │
│   GraphQL    │     │     CLI      │     │  HTML/Excel  │
│     API      │◀────│              │     │              │
└──────────────┘     └──────────────┘     └──────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │  File Cache  │
                     │   (JSON)     │
                     └──────────────┘
```

### Project Structure

```
wttj-metrics/
├── bin/
│   └── wttj-metrics              # CLI entry point
├── lib/
│   ├── wttj_metrics.rb           # Main module, config, autoloading
│   └── wttj_metrics/
│       ├── cli.rb                # Thor CLI commands
│       ├── linear_client.rb      # Linear API client (Net::HTTP)
│       ├── file_cache.rb         # JSON file-based caching
│       ├── csv_writer.rb         # CSV output writer
│       ├── metrics_calculator.rb # Facade for metric calculations
│       ├── metrics/              # Specialized calculators
│       │   ├── base.rb           # Template base class
│       │   ├── bug_calculator.rb
│       │   ├── cycle_calculator.rb
│       │   ├── distribution_calculator.rb
│       │   ├── flow_calculator.rb
│       │   ├── team_calculator.rb
│       │   ├── team_stats_calculator.rb
│       │   └── timeseries_collector.rb
│       ├── report_generator.rb   # HTML/Excel report orchestrator
│       ├── chart_data_builder.rb # Chart.js data preparation
│       ├── cycle_parser.rb       # Cycle/sprint data parser
│       ├── excel_report_builder.rb
│       ├── metrics_parser.rb     # CSV metrics parser
│       ├── weekly_data_aggregator.rb
│       ├── helpers/              # View helpers
│       │   ├── date_helper.rb
│       │   ├── formatting_helper.rb
│       │   └── issue_helper.rb
│       ├── presenters/           # Data presenters for views
│       │   ├── base_presenter.rb
│       │   ├── bug_metric_presenter.rb
│       │   ├── bug_team_presenter.rb
│       │   ├── cycle_metric_presenter.rb
│       │   ├── cycle_presenter.rb
│       │   ├── flow_metric_presenter.rb
│       │   └── team_metric_presenter.rb
│       └── templates/
│           └── report.html.erb   # HTML report template
├── spec/                         # RSpec tests
│   ├── cassettes/                # VCR HTTP recordings
│   ├── support/                  # Test helpers
│   └── wttj_metrics/             # Unit tests
├── .devcontainer/                # VS Code dev container config
├── .github/
│   └── workflows/
│       └── ci.yml                # GitHub Actions CI
├── Gemfile
├── Gemfile.lock
├── CHANGELOG.md
└── README.md
```

### Key Components

| Component | Responsibility |
|-----------|----------------|
| **CLI** | Thor-based command interface, option parsing |
| **LinearClient** | GraphQL API communication, pagination, caching |
| **MetricsCalculator** | Facade coordinating specialized calculators |
| **Metrics::*** | Single-responsibility metric calculators |
| **ReportGenerator** | Report orchestration, template rendering |
| **Presenters** | Data formatting for HTML/Excel display |
| **FileCache** | JSON-based response caching |

### Data Flow

```
1. CLI invokes collect command
   │
   ▼
2. LinearClient fetches data from API (with optional caching)
   │
   ▼
3. MetricsCalculator processes raw data through specialized calculators
   │
   ▼
4. CsvWriter outputs metrics to CSV file
   │
   ▼
5. CLI invokes report command
   │
   ▼
6. MetricsParser reads CSV data
   │
   ▼
7. ReportGenerator coordinates data transformation
   │
   ▼
8. ChartDataBuilder + Presenters format data
   │
   ▼
9. ERB template renders HTML (or ExcelReportBuilder generates .xlsx)
```

---

## Linear API Integration

### Required Permissions

Your Linear API key needs read access to:
- **Issues** - For ticket metrics, flow data, and distributions
- **Cycles** - For sprint/cycle metrics and velocity
- **Users** - For team member information
- **Workflow States** - For status categorization

### GraphQL Queries

The tool uses Linear's GraphQL API to fetch:

| Query | Data Retrieved |
|-------|----------------|
| `issues` | All issues with history, states, assignees, labels, cycles |
| `cycles` | Sprint data with issues and progress |
| `users` | Team member list |
| `workflowStates` | Workflow configuration |

Example issue query structure:
```graphql
query($after: String) {
  issues(first: 100, after: $after) {
    pageInfo { hasNextPage, endCursor }
    nodes {
      id, identifier, title, createdAt, updatedAt, completedAt
      startedAt, canceledAt, estimate, priority, priorityLabel
      state { id, name, type }
      assignee { id, name, email }
      team { id, name }
      cycle { id, name, startsAt, endsAt }
      labels { nodes { name } }
      history(first: 50) {
        nodes { createdAt, fromState { name, type }, toState { name, type } }
      }
    }
  }
}
```

### Rate Limiting

- The Linear API has rate limits (typically 1500 requests/hour for read operations)
- The tool uses pagination (100 items per request) to minimize API calls
- **Caching is enabled by default** - subsequent runs use cached data
- Use `--clear-cache` when you need fresh data

---

## Development

### Prerequisites

- Ruby 3.2+ (see `.ruby-version` or CI config for recommended version)
- Bundler 2.x

```bash
# Install Ruby (using rbenv)
# Check .ruby-version or .github/workflows/ci.yml for the current recommended version
rbenv install 3.4  # Install latest 3.4.x or your preferred 3.2+ version
rbenv local 3.4

# Install Bundler
gem install bundler

# Install dependencies
bundle install
```

### Dev Container

For a pre-configured development environment, use VS Code with Dev Containers:

```bash
code .
# Command Palette (Ctrl/Cmd+Shift+P) > Dev Containers: Reopen in Container
```

The dev container provides:
- Ruby 3.4
- All gem dependencies
- GitHub CLI
- Proper environment variable forwarding

### Code Style

This project uses RuboCop for code style enforcement:

```bash
# Run RuboCop
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -a

# Run Reek for code smells
bundle exec reek lib/
```

### Testing

Tests use RSpec with VCR for HTTP recording and WebMock for stubbing:

```bash
# Run all tests
bundle exec rspec

# Run specific spec file
bundle exec rspec spec/wttj_metrics/metrics/flow_calculator_spec.rb

# Run with documentation format
bundle exec rspec --format documentation

# Run with coverage report
bundle exec rspec
open coverage/index.html
```

#### Test Patterns

- **4-phase test pattern**: Setup, Exercise, Verify, Teardown
- **`aggregate_failures`**: Group related expectations
- **Named subjects**: Clear test naming

### Running Locally

```bash
# Ensure you have a .env file with LINEAR_API_KEY
echo "LINEAR_API_KEY=your_key_here" > .env

# Run collection
./bin/wttj-metrics collect -o test_metrics.csv

# Generate report
./bin/wttj-metrics report test_metrics.csv -o test_report.html

# View report
open test_report.html
```

---

## Troubleshooting

### Common Issues

#### "LINEAR_API_KEY is not set"

**Cause:** Missing environment variable

**Solution:**
```bash
# Create .env file
echo "LINEAR_API_KEY=lin_api_xxxxx" > .env

# Or export directly
export LINEAR_API_KEY=lin_api_xxxxx
```

#### "CSV file not found"

**Cause:** Running report command before collect

**Solution:**
```bash
# Run collect first
./bin/wttj-metrics collect -o metrics.csv
./bin/wttj-metrics report metrics.csv
```

#### SSL Certificate Errors

**Cause:** Missing or outdated SSL certificates

**Solution:**
```bash
# Update SSL certificates (macOS)
brew install openssl
bundle config build.openssl --with-openssl-dir=$(brew --prefix openssl)
bundle install
```

#### Stale Data in Reports

**Cause:** Cached API responses

**Solution:**
```bash
# Clear cache and re-collect
./bin/wttj-metrics collect --clear-cache -o metrics.csv
```

#### "Rate limit exceeded" from Linear

**Cause:** Too many API requests

**Solution:**
```bash
# Wait and use cached data
./bin/wttj-metrics collect  # Uses cache by default

# Check when cache was last updated
ls -la cache/
```

#### Missing Teams in Report

**Cause:** Team filtering is active

**Solution:**
```bash
# Use --all-teams to see all teams
./bin/wttj-metrics report metrics.csv --all-teams

# Or specify your teams explicitly
./bin/wttj-metrics report metrics.csv --teams "Your Team" "Another Team"
```

---

## Contributing

We welcome contributions! Here's how to get started:

### Development Workflow

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Run tests and linting**
   ```bash
   bundle exec rspec
   bundle exec rubocop
   ```
5. **Commit your changes**
   ```bash
   git commit -m "Add: your feature description"
   ```
6. **Push and create a Pull Request**

### Commit Message Format

Use conventional commits:
- `Add:` for new features
- `Fix:` for bug fixes
- `Refactor:` for code improvements
- `Docs:` for documentation changes
- `Test:` for test additions/modifications

### Code Guidelines

- Follow existing code style (enforced by RuboCop)
- Add tests for new functionality
- Update documentation as needed
- Keep changes focused and minimal

### Pull Request Checklist

- [ ] Tests pass (`bundle exec rspec`)
- [ ] Linting passes (`bundle exec rubocop`)
- [ ] Documentation updated (if applicable)
- [ ] CHANGELOG.md updated

---

## Dependencies

### Runtime Dependencies

| Gem | Purpose |
|-----|---------|
| `thor` | CLI framework |
| `zeitwerk` | Autoloading |
| `dotenv` | Environment variables |
| `caxlsx` | Excel file generation |
| `csv` | CSV parsing (required from Ruby 3.4+) |
| `openssl` | SSL/TLS support |

### Development Dependencies

| Gem | Purpose |
|-----|---------|
| `rspec` | Testing framework |
| `vcr` | HTTP interaction recording |
| `webmock` | HTTP request stubbing |
| `simplecov` | Code coverage |
| `rubocop` | Code linting |
| `rubocop-rspec` | RSpec-specific linting |
| `rubocop-performance` | Performance cops |
| `reek` | Code smell detector |
| `bundler-audit` | Dependency vulnerability check |

> **Note:** See [Gemfile](Gemfile) for specific version constraints.

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

<p align="center">
  Built with ❤️ for <a href="https://www.welcometothejungle.com">Welcome to the Jungle</a> engineering teams
</p>
