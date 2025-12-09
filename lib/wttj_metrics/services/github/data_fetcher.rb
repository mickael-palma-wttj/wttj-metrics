# frozen_string_literal: true

module WttjMetrics
  module Services
    module Github
      class DataFetcher
        def initialize(logger, days = 90)
          @logger = logger
          @days = days
        end

        def call
          @logger.info '📊 Fetching data from GitHub...'

          from_date = (Date.today - @days).iso8601
          prs = fetch_prs(from_date)
          return {} if prs.empty?

          filtered_prs = filter_prs(prs, from_date)

          @logger.info "   Found #{filtered_prs.size} pull requests (created >= #{from_date})"

          { pull_requests: filtered_prs }
        rescue StandardError => e
          @logger.error "❌ Error fetching GitHub data: #{e.message}"
          {}
        end

        private

        def fetch_prs(from_date)
          if ENV['GITHUB_ORG']
            fetch_org_prs(ENV['GITHUB_ORG'], from_date)
          elsif ENV['GITHUB_REPO']
            @logger.info "   Fetching for repository: #{ENV['GITHUB_REPO']}"
            client.fetch_pull_requests(ENV['GITHUB_REPO'], from_date)
          else
            @logger.error '❌ GITHUB_ORG or GITHUB_REPO environment variable is not set'
            []
          end
        end

        def fetch_org_prs(org, from_date)
          @logger.info "   Fetching for organization: #{org}"
          cache_key = "github_prs_#{org}"
          cached_prs = cache.read(cache_key, max_age_hours: 87_600) || []

          prs = if cached_prs.any?
                  merge_with_cache(org, cached_prs, from_date)
                else
                  @logger.info "   No cache found. Fetching all PRs since #{from_date}..."
                  client.fetch_organization_pull_requests(org, from_date)
                end

          cache.write(cache_key, prs)
          prs
        end

        def merge_with_cache(org, cached_prs, from_date)
          latest_update = cached_prs.filter_map { |pr| pr['updatedAt'] }.max
          since_date = latest_update || from_date

          @logger.info "   Found #{cached_prs.size} cached PRs. Fetching updates since #{Date.parse(since_date)}..."
          new_prs = client.fetch_organization_pull_requests_updated_after(org, since_date)

          pr_map = cached_prs.to_h { |pr| [pr['url'], pr] }
          new_prs.each { |pr| pr_map[pr['url']] = pr }

          pr_map.values
        end

        def filter_prs(prs, from_date)
          filtered = prs.select do |pr|
            pr['createdAt'] >= from_date
          end
          filtered.map { |pr| deep_symbolize_keys(pr) }
        end

        def client
          @client ||= Sources::Github::Client.new(logger: @logger)
        end

        def cache
          @cache ||= Data::FileCache.new
        end

        def deep_symbolize_keys(obj)
          case obj
          when Array
            obj.map { |v| deep_symbolize_keys(v) }
          when Hash
            obj.each_with_object({}) do |(k, v), result|
              result[k.to_sym] = deep_symbolize_keys(v)
            end
          else
            obj
          end
        end
      end
    end
  end
end
