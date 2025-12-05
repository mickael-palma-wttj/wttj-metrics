# WTTJ Metrics

A Ruby CLI tool to collect metrics from [Linear](https://linear.app) and generate beautiful HTML/Excel reports. Built for Welcome to the Jungle engineering teams.

![Ruby](https://img.shields.io/badge/Ruby-3.2+-red?logo=ruby)
![License](https://img.shields.io/badge/License-MIT-blue)

## Features

- 📊 **Collect Metrics** - Fetch issues, cycles, and team data from Linear API
- 📈 **HTML Dashboard** - Interactive charts with Chart.js (flow, bugs, cycles, distributions)
- 📑 **Excel Export** - Detailed spreadsheets for further analysis
- 🐛 **Bug Tracking** - Track bug creation/resolution by team over time
- ⚡ **Caching** - Smart API response caching for faster subsequent runs
- 🎨 **WTTJ Branding** - Dashboard styled with Welcome to the Jungle colors

## Dashboard Sections

| Section | Description |
|---------|-------------|
| **Key Metrics** | Cycle time, lead time, WIP, throughput, completion rate |
| **Bugs** | Open bugs, resolution rate, bugs by priority, bug flow by team |
| **Ticket Flow** | Created vs completed tickets over time, state transitions |
| **Distributions** | Status, priority, type, and assignee breakdowns |
| **Cycles** | Sprint metrics, velocity, commitment accuracy, team performance |

## Installation

### Prerequisites

- Ruby 3.2+
- Bundler
- Linear API key

### Setup

```bash
# Clone the repository
git clone https://github.com/your-org/wttj-metrics.git
cd wttj-metrics

# Install dependencies
bundle install

# Configure environment
cp .env.example .env
```

Edit `.env` with your Linear credentials:

```bash
LINEAR_API_KEY=lin_api_xxxxxxxxxxxxxxxxxxxxx
```

## Usage

### Collect Metrics

Fetch data from Linear API and save to CSV:

```bash
# Default output to tmp/metrics.csv
./bin/wttj-metrics collect

# Custom output path
./bin/wttj-metrics collect -o metrics.csv

# Clear cache before fetching
./bin/wttj-metrics collect --clear-cache

# Disable caching
./bin/wttj-metrics collect --no-cache
```

### Generate Report

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

### Full Workflow

```bash
# Collect fresh data and generate report
./bin/wttj-metrics collect -o metrics.csv && \
./bin/wttj-metrics report metrics.csv --days 365 --excel
```

### Cache Management

```bash
# Clear all cached API responses
./bin/wttj-metrics cache clear
```

## Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `LINEAR_API_KEY` | Yes | Your Linear API key |
| `CSV_OUTPUT_PATH` | No | Default CSV output path |

### Team Filtering

By default, the report filters metrics to selected teams. You can control this via CLI options:

```bash
# Use default teams (ATS, Marketplace, Platform, ROI, Sourcing)
./bin/wttj-metrics report metrics.csv

# Specify custom teams
./bin/wttj-metrics report metrics.csv --teams ATS Platform Sourcing

# Show all teams from the data (no filtering)
./bin/wttj-metrics report metrics.csv --all-teams
```

To change the default teams, edit `SELECTED_TEAMS` in `lib/wttj_metrics/report_generator.rb`:

```ruby
SELECTED_TEAMS = %w[ATS Marketplace Platform ROI Sourcing].freeze
```

Filtered charts display a "Filtered" badge. When using `--all-teams`, all teams from the data are included and no filter badge is shown.

## Development

### Project Structure

```
wttj-metrics/
├── bin/
│   └── wttj-metrics          # CLI entry point
├── lib/
│   └── wttj_metrics/
│       ├── cli.rb            # Thor CLI commands
│       ├── linear_client.rb  # Linear API client (Net::HTTP)
│       ├── metrics_calculator.rb  # Facade for metric calculations
│       ├── metrics/          # Specialized calculators
│       │   ├── base.rb
│       │   ├── bug_calculator.rb
│       │   ├── cycle_calculator.rb
│       │   ├── distribution_calculator.rb
│       │   ├── flow_calculator.rb
│       │   ├── team_calculator.rb
│       │   ├── team_stats_calculator.rb
│       │   └── timeseries_collector.rb
│       ├── report_generator.rb
│       ├── chart_data_builder.rb
│       ├── cycle_parser.rb
│       ├── excel_report_builder.rb
│       ├── metrics_parser.rb
│       ├── weekly_data_aggregator.rb
│       └── templates/
│           └── report.html.erb
├── spec/                     # RSpec tests
│   ├── support/
│   │   ├── rspec_config.rb
│   │   ├── shared_examples.rb
│   │   └── vcr.rb
│   └── wttj_metrics/
├── .devcontainer/            # VS Code dev container
├── Gemfile
└── README.md
```

### Dev Container

Open in VS Code with Dev Containers extension for a pre-configured Ruby environment:

```bash
code .
# Command Palette > Dev Containers: Reopen in Container
```

### Code Style

```bash
# Run RuboCop
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -a
```

### Testing

```bash
# Run all tests
bundle exec rspec

# Run specific spec file
bundle exec rspec spec/wttj_metrics/metrics/flow_calculator_spec.rb

# Run with documentation format
bundle exec rspec --format documentation
```

Tests use VCR for recording/replaying HTTP interactions and WebMock for stubbing.

## Dependencies

| Gem | Purpose |
|-----|---------||
| `thor` | CLI framework |
| `zeitwerk` | Autoloading |
| `dotenv` | Environment variables |
| `caxlsx` | Excel file generation |
| `rspec` | Testing framework |
| `vcr` | HTTP interaction recording |
| `webmock` | HTTP request stubbing |
| `rubocop` | Code linting |
| `rubocop-rspec` | RSpec-specific linting |

## License

MIT License - see [LICENSE](LICENSE) for details.

---

Built with ❤️ for Welcome to the Jungle engineering teams.
