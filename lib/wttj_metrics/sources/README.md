# Sources

This directory contains data source integrations for fetching metrics data from external systems. Currently supports Linear (project management) and GitHub (code collaboration).

## Architecture

The sources layer provides:
- API client implementations for external systems
- Query builders for constructing API requests
- Data transformation from API responses to domain objects
- Error handling and retry logic
- Caching support for API responses

## Subdirectories

### linear/

Integration with the Linear GraphQL API for fetching issues, cycles, teams, and workflow data.

**Files:**
- `client.rb` - Linear API client with GraphQL support
- `query_builder.rb` - Builds GraphQL queries for Linear API

### github/

Integration with the GitHub GraphQL API for fetching pull requests, reviews, and comments.

**Files:**
- `client.rb` - GitHub API client with GraphQL support

## GitHub Integration

### Client

GraphQL client for the GitHub API with caching, pagination, and error handling.

**Responsibilities:**
- Execute GraphQL queries against GitHub API
- Handle authentication with Personal Access Token
- Paginate through large result sets (PRs, reviews, comments)
- Handle rate limiting (429) and authentication errors (401)
- Retry logic for transient failures (Gateway Timeout, etc.)

**Key Methods:**
```ruby
client = Sources::Github::Client.new(logger: logger)

# Fetch PRs for a repository
prs = client.fetch_pull_requests('owner/repo', '2025-01-01')

# Fetch PRs for an organization (recursive splitting for large datasets)
prs = client.fetch_organization_pull_requests('org-name', '2025-01-01')
```

## Linear Integration

### Client

GraphQL client for the Linear API with caching, pagination, and error handling.

**Responsibilities:**
- Execute GraphQL queries against Linear API
- Handle authentication with API key
- Paginate through large result sets
- Cache API responses to reduce API calls
- Transform API responses to Ruby hashes
- Handle rate limiting and errors

**Key Methods:**
```ruby
client = Sources::Linear::Client.new(api_key: 'lin_api_...', cache: cache)

# Fetch all issues (with automatic pagination)
issues = client.fetch_all_issues
# => [{ id: '...', title: '...', state: {...}, ... }, ...]

# Fetch all cycles/sprints
cycles = client.fetch_cycles
# => [{ id: '...', name: 'Sprint 49', startDate: '...', ... }, ...]

# Fetch team members
members = client.fetch_team_members
# => [{ id: '...', name: 'John Doe', email: '...', ... }, ...]

# Fetch workflow states
states = client.fetch_workflow_states
# => [{ id: '...', name: 'In Progress', type: 'started', ... }, ...]

# Execute custom query
result = client.query(custom_graphql_query, variables: { teamId: '...' })
```

**Features:**

1. **Authentication**
   - API key from environment variable (`LINEAR_API_KEY`)
   - Automatic header injection
   - Secure credential handling

2. **Caching**
   - Optional file-based caching
   - Configurable cache duration
   - Cache key based on query
   - Automatic cache invalidation

3. **Pagination**
   - Automatic handling of paginated responses
   - Fetches all pages until complete
   - Configurable page size (default: 50)
   - Progress logging for large datasets

4. **Error Handling**
   - Network error detection
   - API error parsing from GraphQL responses
   - Retry logic for transient failures
   - Detailed error messages

5. **Logging**
   - Cache hit/miss logging
   - API call logging
   - Pagination progress
   - Error logging

**API Endpoints:**
- GraphQL endpoint: `https://api.linear.app/graphql`
- Authentication: Bearer token in Authorization header
- Rate limit: 1000 requests per hour (handled automatically)

**GraphQL Queries:**

The client uses predefined GraphQL queries for common operations:

```graphql
# Issues query
query($after: String) {
  issues(first: 50, after: $after) {
    pageInfo {
      hasNextPage
      endCursor
    }
    nodes {
      id
      title
      description
      state { name, type }
      priority
      priorityLabel
      team { name, key }
      assignee { name, email }
      creator { name, email }
      cycle { name, startsAt, endsAt }
      createdAt
      updatedAt
      completedAt
      canceledAt
      estimate
      labels { nodes { name } }
    }
  }
}
```

**Usage Example:**
```ruby
# Initialize with cache
cache = Data::FileCache.new
client = Sources::Linear::Client.new(cache: cache)

# First call - fetches from API
issues = client.fetch_all_issues
# => 🌐 Fetching issues_all from API...
# => Fetched 6034 issues in 12.5 seconds

# Second call - uses cache
issues = client.fetch_all_issues
# => 📦 Using cached issues_all (0.5h old)
# => Returns instantly
```

### QueryBuilder

Builds GraphQL queries for the Linear API with field selection and filtering.

**Responsibilities:**
- Construct GraphQL query strings
- Handle field selection
- Apply filters and arguments
- Format query parameters
- Provide reusable query fragments

**Key Methods:**
```ruby
builder = Sources::Linear::QueryBuilder.new

# Build issues query
query = builder.issues_query(fields: [:id, :title, :state])
# => "query { issues { nodes { id title state { name } } } }"

# Build query with pagination
query = builder.issues_query(after: cursor, first: 100)
# => "query($after: String) { issues(first: 100, after: $after) { ... } }"

# Build cycles query
query = builder.cycles_query
# => "query { cycles { nodes { id name startsAt endsAt } } }"

# Build filtered query
query = builder.issues_query(filter: { team: { id: { eq: 'team_123' } } })
```

**Query Templates:**

1. **Issues Query**: All issue fields with team, assignee, cycle
2. **Cycles Query**: Cycle/sprint data with dates
3. **Teams Query**: Team information and settings
4. **Users Query**: User/member data
5. **Workflow States Query**: Workflow configuration

**Features:**
- Field selection (request only needed fields)
- Filter support (team, assignee, status, etc.)
- Pagination arguments
- Nested field resolution
- Query validation

## Configuration

### Environment Variables

```bash
# Required: Linear API key
export LINEAR_API_KEY="lin_api_xxxxxxxxxxxxx"

# Optional: API endpoint (defaults to Linear's production API)
export LINEAR_API_URL="https://api.linear.app/graphql"
```

### API Key Setup

1. Go to Linear Settings → API → Personal API Keys
2. Create new API key with read permissions
3. Copy key and set `LINEAR_API_KEY` environment variable
4. Verify with: `echo $LINEAR_API_KEY`

### Cache Configuration

```ruby
# Enable cache (default)
cache = Data::FileCache.new
client = Sources::Linear::Client.new(cache: cache)

# Disable cache (always fetch fresh)
client = Sources::Linear::Client.new(cache: nil)

# Custom cache location
cache = Data::FileCache.new('custom/cache/path')
client = Sources::Linear::Client.new(cache: cache)
```

## Data Models

### Issue Structure
```ruby
{
  id: "abc-123",
  title: "Fix login bug",
  description: "Users cannot login",
  state: { name: "In Progress", type: "started" },
  priority: 2,
  priorityLabel: "High",
  team: { name: "ATS", key: "ATS" },
  assignee: { name: "John Doe", email: "john@example.com" },
  creator: { name: "Jane Smith", email: "jane@example.com" },
  cycle: { name: "Sprint 49", startsAt: "2024-12-02", endsAt: "2024-12-08" },
  createdAt: "2024-12-01T10:00:00Z",
  updatedAt: "2024-12-05T14:30:00Z",
  completedAt: "2024-12-05T14:30:00Z",
  canceledAt: nil,
  estimate: 3,
  labels: { nodes: [{ name: "bug" }, { name: "urgent" }] }
}
```

### Cycle Structure
```ruby
{
  id: "cycle-123",
  name: "Sprint 49",
  startsAt: "2024-12-02",
  endsAt: "2024-12-08",
  issues: { nodes: [...] },
  team: { name: "ATS", key: "ATS" }
}
```

### Workflow State Structure
```ruby
{
  id: "state-123",
  name: "In Progress",
  type: "started",
  color: "#FFB800",
  position: 2
}
```

## Error Handling

### Network Errors
```ruby
begin
  issues = client.fetch_all_issues
rescue Sources::Linear::Client::NetworkError => e
  puts "Network error: #{e.message}"
  # Retry or handle gracefully
end
```

### API Errors
```ruby
begin
  issues = client.fetch_all_issues
rescue Sources::Linear::Client::ApiError => e
  puts "API error: #{e.message}"
  # Check API key, rate limits, etc.
end
```

### Rate Limiting
The client automatically handles rate limits by:
- Respecting `Retry-After` headers
- Exponential backoff for retries
- Logging rate limit warnings

## Performance Considerations

### API Call Optimization
- **Batch requests**: Fetch all data at once when possible
- **Caching**: Enable caching to reduce API calls (24-hour default)
- **Pagination**: Automatic, fetches in chunks of 50 items
- **Field selection**: Request only needed fields to reduce payload size

### Typical Performance
- Issues (6000 items): ~10-15 seconds without cache, instant with cache
- Cycles (125 items): ~1-2 seconds without cache, instant with cache
- Team members (50 items): <1 second
- Workflow states (20 items): <1 second

### Memory Usage
- Issues data: ~5-10 MB for 6000 issues
- Total API data: ~10-15 MB
- Cached data: ~10-15 MB on disk

## Testing

Linear client has comprehensive test coverage using VCR for API mocking:
- `spec/wttj_metrics/sources/linear/client_spec.rb`
- VCR cassettes in `spec/cassettes/WttjMetrics_Sources_Linear_Client/`

Run tests:
```bash
bundle exec rspec spec/wttj_metrics/sources/
```

## Adding New Data Sources

To add a new data source (e.g., Jira, GitHub):

1. Create subdirectory: `sources/jira/`
2. Implement client: `sources/jira/client.rb`
3. Implement query builder (if needed): `sources/jira/query_builder.rb`
4. Follow same patterns as Linear client:
   - Cache support
   - Error handling
   - Pagination
   - Logging
5. Add tests with VCR or similar mocking

## Dependencies

**Internal:**
- `Data::FileCache` - Caching API responses
- `Config` - Configuration management

**External:**
- `net/http` - HTTP client
- `uri` - URI parsing
- `json` - JSON parsing

## Integration Points

**Used By:**
- `Services::DataFetcher` - Fetches data for reports
- `CLI` - Direct API access for debugging

**Uses:**
- `Data::FileCache` - Cache API responses
- `Config` - API credentials and endpoints

## Future Enhancements

1. **GraphQL Fragments**: Reusable field selections
2. **Batch Operations**: Multiple queries in one request
3. **Webhooks**: Real-time updates instead of polling
4. **Incremental Sync**: Fetch only changed data
5. **Query Optimization**: Request only needed date ranges
6. **Parallel Requests**: Fetch multiple resources simultaneously
7. **Compression**: Gzip responses to reduce bandwidth
