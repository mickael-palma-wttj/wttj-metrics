# Linear Metrics

This directory contains calculators for analyzing Linear issue data. These calculators process raw issue and cycle data to generate insights about flow, bugs, team performance, and sprint execution.

## Calculators

### BugCalculator
Calculates metrics related to bug tracking and resolution.

**Metrics:**
- **Bug Status**: Counts of bugs in various states (Open, In Progress, Completed, Cancelled).
- **Bug Priority**: Distribution of bugs by priority level (Urgent, High, Medium, Low).
- **MTTR (Mean Time To Resolution)**: Average time taken to resolve bugs.
- **Resolution Rate**: Percentage of bugs resolved compared to total bugs.
- **Bug Flow**: Weekly trends of bugs opened vs. bugs closed.

### CycleCalculator
Analyzes performance within Linear cycles (sprints).

**Metrics:**
- **Scope Change Rate**: Percentage of scope added after the cycle started.
- **Completion Rate**: Percentage of planned work completed within the cycle.
- **Time to Completion**: Average time to complete issues within the cycle.
- **Cycle Velocity**: Total story points or issue count completed in the cycle.
- **Progress**: Real-time completion percentage for active cycles.

### DistributionCalculator
Analyzes the distribution of issues across different dimensions.

**Metrics:**
- **Team Distribution**: Number of issues assigned to each team.
- **Priority Distribution**: Number of issues per priority level.
- **Type Distribution**: Number of issues per type (Feature, Bug, Improvement, etc.).
- **Status Distribution**: Number of issues in each workflow state.

### FlowCalculator
Calculates Kanban/Flow metrics to measure process efficiency.

**Metrics:**
- **Throughput**: Number of issues completed per unit of time (e.g., weekly).
- **Work in Progress (WIP)**: Number of issues currently in progress.
- **Cycle Time**: Average time from starting work on an issue to completing it.
- **Lead Time**: Average time from issue creation to completion.
- **Flow Efficiency**: Ratio of active work time to total lead time.

### TeamCalculator
Calculates high-level performance metrics for teams.

**Metrics:**
- **Team Velocity**: Average velocity (points/count) for the team.
- **Bug Rate**: Percentage of the team's work that is bug-related.
- **Completion Rate**: The team's reliability in finishing planned work.
- **Average Cycle Time**: The team's speed in delivering individual items.
- **Team Capacity**: The total workload the team can handle.

### TeamStatsCalculator
Provides detailed statistical analysis for team performance.

**Metrics:**
- **Completion Statistics**: Mean, median, and distribution of completion rates over time.
- **Velocity Trends**: Analysis of velocity stability and trends.
- **Quality Metrics**: Detailed breakdown of bug rates and resolution efficiency.
- **Capacity Utilization**: How effectively the team uses its planned capacity.

### TimeseriesCalculator
Calculates timeseries metrics from Linear issues, tracking daily statistics for tickets, bugs, and state transitions.

**Features:**
- **Composition Pattern**: Uses specialized metric classes (TicketMetrics, BugMetrics, TransitionMetrics)
- **Single Responsibility**: Each metric class handles one type of data
- **Date-Based Grouping**: Tracks metrics per date for accurate timeseries
- **Team Breakdowns**: Provides team-specific metrics for all tracked data
- **MTTR Calculation**: Tracks Mean Time To Resolve for bugs by team

See [timeseries/README.md](timeseries/README.md) for detailed documentation.

## Supporting Modules

### CycleParser
Parses and organizes cycle metrics by team.

**Responsibilities:**
- Parses cycle metric data from CSV format
- Organizes metrics by team and cycle
- Applies appropriate type conversions (integer, float, string)

**Configuration:**
- Uses `CycleParserConfig` module for parser configuration
- Supports custom team selection
- Handles metric validation and parsing errors

### CycleParserConfig
Configuration module for cycle metric parsing.

**Constants:**
- **DEFAULT_TEAMS**: Default teams for cycle parsing
- **METRIC_PARTS_COUNT**: Expected parts when splitting metric keys
- **METRIC_PARSERS**: Maps metric names to parser functions (integer, rounded float, string)

**Design Note:**
- Extracted from `CycleParser` to follow Single Responsibility Principle
- Configuration modules are expected to contain multiple constants
- Uses lambda functions for type conversion flexibility

## Usage

Calculators are typically instantiated with a set of issues (and optionally other data like cycles or workflow states) and then called to perform the calculation.

```ruby
# Example usage
calculator = WttjMetrics::Metrics::Linear::BugCalculator.new(issues, workflow_states)
metrics = calculator.calculate

puts "Open Bugs: #{metrics[:bug_status][:open]}"
puts "MTTR: #{metrics[:mttr]} hours"
```
