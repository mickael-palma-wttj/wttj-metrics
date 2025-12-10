# Timeseries Metrics

This directory contains classes responsible for calculating daily time-series metrics for GitHub activity. These metrics are aggregated by day to provide trends over time.

## Components

### `DailyStats`
The main aggregator class that coordinates the collection of various metrics for a specific day. It delegates specific metric calculations to specialized classes.

### Metric Classes

*   **`PrActivityMetrics`**: Tracks Pull Request lifecycle events.
    *   `created`: Number of PRs created.
    *   `merged`: Number of PRs merged.
    *   `closed`: Number of PRs closed without merging.
    *   `open`: Number of PRs still open.
    *   `avg_time_to_merge_hours`: Average time from creation to merge.

*   **`ReviewMetrics`**: Tracks code review activity and efficiency.
    *   `avg_reviews_per_pr`: Average number of reviews per PR.
    *   `avg_comments_per_pr`: Average number of comments per PR.
    *   `avg_rework_cycles`: Average number of "Changes Requested" cycles.
    *   `avg_time_to_first_review_days`: Average time from PR creation to the first review.
    *   `avg_time_to_approval_days`: Average time from PR creation to approval.
    *   `unreviewed_pr_rate`: Percentage of PRs with zero reviews.

*   **`CodeMetrics`**: Tracks code volume changes.
    *   `avg_additions_per_pr`: Average lines of code added per PR.
    *   `avg_deletions_per_pr`: Average lines of code deleted per PR.

*   **`CiMetrics`**: Tracks Continuous Integration performance.
    *   `ci_success_rate`: Percentage of commits with a successful CI status.
    *   `avg_time_to_green_hours`: Average time from commit to a successful check suite.

*   **`ReleaseMetrics`**: Tracks release frequency and stability.
    *   `releases_count`: Number of releases created.
    *   `hotfix_count`: Number of releases identified as hotfixes.
    *   `hotfix_rate`: Percentage of releases that are hotfixes.
    *   `deploy_frequency_daily`: Daily deployment frequency.

## Usage

These classes are primarily used by the `TimeseriesCalculator` to generate the `github_daily` dataset.
