# GitHub Metrics

This directory contains calculators for analyzing GitHub pull request data. These calculators process raw PR data to generate insights about velocity, quality, collaboration, and activity.

## Calculators

### PrVelocityCalculator
Calculates velocity-related metrics for Pull Requests.

**Metrics:**
- **Avg Time to Merge**: Average duration from PR creation to merge.
- **Avg Time to First Review**: Average duration from PR creation to the first review comment.
- **Avg Reviews per PR**: Average number of reviews received per PR.
- **Avg Comments per PR**: Average number of comments (general comments) per PR.

### QualityCalculator
Analyzes code quality indicators.

**Metrics:**
- **Merge Rate**: Percentage of PRs that are merged.
- **Unreviewed PR Rate**: Percentage of PRs merged without review.
- **CI Success Rate**: Percentage of successful CI runs.
- **Hotfix Rate**: Percentage of PRs identified as hotfixes.
- **Time to Green**: Average time for CI to pass.

### PrSizeCalculator
Analyzes the size of Pull Requests.

**Metrics:**
- **Avg Additions**: Average lines added per PR.
- **Avg Deletions**: Average lines deleted per PR.
- **Avg Changed Files**: Average files changed per PR.
- **Avg Commits**: Average commits per PR.

### RepositoryActivityCalculator
Analyzes activity levels across different repositories.

**Metrics:**
- **Top 10 Repositories**: Lists the 10 most active repositories based on PR count.
- **Daily Activity**: Breakdown of PRs created per repository per day.

### TimeseriesCalculator
Generates comprehensive daily time-series data for PR lifecycle events, code quality, and release activity.

**Metrics:**
- **PR Activity**: Created, Merged, Closed, Open counts, and Merge Time.
- **Review Efficiency**: Reviews/Comments per PR, Rework Cycles, Time to First Review/Approval.
- **Code Volume**: Additions and Deletions per PR.
- **CI Performance**: Success Rate and Time to Green.
- **Release Activity**: Release counts and Hotfix rates.

See [Timeseries Metrics](timeseries/README.md) for detailed component documentation.

### CollaborationCalculator
Analyzes how teams collaborate through code reviews.

**Metrics:**
- **Cross-Team Reviews**: Identifies reviews where the reviewer and author belong to different teams.
- **Review Distribution**: Shows the distribution of review workload among team members.

### ContributorActivityCalculator
Tracks individual contributions to the codebase.

**Metrics:**
- **PRs Created**: Number of PRs opened by each contributor.
- **PRs Merged**: Number of PRs merged for each contributor.
- **Reviews Given**: Number of reviews submitted by each contributor.
- **Comments Made**: Number of comments posted by each contributor.

### PrSizeCalculator
Analyzes the size of Pull Requests to encourage smaller, more manageable changes.

**Metrics:**
- **Lines Changed**: Total additions and deletions.
- **Files Changed**: Number of files modified in the PR.
- **Size Distribution**: Categorizes PRs into buckets (e.g., Small, Medium, Large) based on lines changed.

### QualityCalculator
Measures indicators of code quality and process health.

**Metrics:**
- **Pass Rate**: Percentage of PRs that pass CI/CD checks.
- **Revert Rate**: Percentage of PRs that are reverts of previous commits.
- **Review Depth**: Average number of comments per review, indicating the thoroughness of reviews.

## Usage

Calculators are typically instantiated with a collection of PR data and then called to perform the calculation.

```ruby
# Example usage
calculator = WttjMetrics::Metrics::Github::PrVelocityCalculator.new(pull_requests)
metrics = calculator.calculate

puts "Average Time to Merge: #{metrics[:avg_time_to_merge]} hours"
```
