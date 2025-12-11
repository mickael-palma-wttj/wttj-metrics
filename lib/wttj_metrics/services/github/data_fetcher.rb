# frozen_string_literal: true

require 'ruby-progressbar'

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

          releases = fetch_releases_data(filtered_prs, from_date)
          @logger.info "   Found #{releases.size} releases"

          teams = fetch_teams_data
          @logger.info "   Found #{teams.size} teams" unless teams.empty?

          { pull_requests: filtered_prs, releases: releases, teams: teams }
        rescue Octokit::Unauthorized
          # Already logged in client
          {}
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
            prs = client.fetch_pull_requests(ENV['GITHUB_REPO'], from_date)
            prs = deep_stringify_keys(prs)
            repo_name = ENV['GITHUB_REPO'].split('/').last
            prs.each { |pr| pr['repository'] ||= { 'name' => repo_name } }
            prs
          else
            @logger.error '❌ GITHUB_ORG or GITHUB_REPO environment variable is not set'
            []
          end
        end

        def fetch_org_prs(org, from_date)
          @logger.info "   Fetching for organization: #{org}"
          cache_key = "github_prs_#{org}"

          # Try fresh cache first (1 day TTL)
          fresh_prs = cache.read(cache_key, max_age_hours: 24)
          if fresh_prs
            @logger.info '   ✨ Cache is fresh (< 24h). Skipping update.'
            return fresh_prs
          end

          cached_prs = cache.read(cache_key, max_age_hours: 87_600) || []

          prs = if cached_prs.any?
                  merge_with_cache(org, cached_prs, from_date)
                else
                  @logger.info "   No cache found. Fetching all PRs since #{from_date}..."
                  prs = client.fetch_organization_pull_requests(org, from_date)
                  deep_stringify_keys(prs)
                end

          cache.write(cache_key, prs)
          prs
        end

        def merge_with_cache(org, cached_prs, from_date)
          latest_update = cached_prs.filter_map { |pr| pr['updatedAt'] }.max
          since_date = latest_update || from_date

          @logger.info "   Found #{cached_prs.size} cached PRs. Fetching updates since #{Date.parse(since_date)}..."
          new_prs = client.fetch_organization_pull_requests_updated_after(org, since_date)
          new_prs = deep_stringify_keys(new_prs)

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

        def fetch_releases_data(prs, from_date)
          if ENV['GITHUB_ORG']
            cache_key = "github_releases_#{ENV['GITHUB_ORG']}"
            fresh_releases = cache.read(cache_key, max_age_hours: 24)
            if fresh_releases
              @logger.info '   ✨ Releases cache is fresh (< 24h). Skipping update.'
              return fresh_releases
            end
          end

          repos = Set.new

          if ENV['GITHUB_REPO']
            repos.add(ENV['GITHUB_REPO'])
          elsif ENV['GITHUB_ORG']
            prs.each do |pr|
              # Handle both symbol and string keys since filter_prs might have symbolized them
              repo_name = pr.dig(:repository, :name) || pr.dig('repository', 'name')
              repos.add("#{ENV.fetch('GITHUB_ORG', nil)}/#{repo_name}") if repo_name
            end
          end

          return [] if repos.empty?

          @logger.info "   Fetching releases for #{repos.size} repositories..."

          progress_bar = ProgressBar.create(
            title: 'Releases',
            total: repos.size,
            format: '%t: |%B| %p%% %e'
          )

          all_releases = []
          repos.each do |repo|
            releases = client.fetch_releases(repo, from_date)
            releases = deep_stringify_keys(releases)

            repo_name = repo.split('/').last
            releases.each { |r| r['repository_name'] = repo_name }

            all_releases.concat(releases)
            progress_bar.increment
          end
          progress_bar.finish

          if ENV['GITHUB_ORG']
            cache_key = "github_releases_#{ENV['GITHUB_ORG']}"
            cache.write(cache_key, all_releases)
          end

          all_releases
        end

        def fetch_teams_data
          return {} unless ENV['GITHUB_ORG']

          @logger.info "   Fetching teams for organization: #{ENV.fetch('GITHUB_ORG', nil)}"
          client.fetch_teams(ENV.fetch('GITHUB_ORG', nil))
        rescue StandardError => e
          @logger.warn "⚠️  Error fetching teams: #{e.message}"
          {}
        end

        def client
          @client ||= Sources::Github::Client.new(logger: @logger)
        end

        def cache
          @cache ||= Data::FileCache.new
        end

        def deep_stringify_keys(obj)
          case obj
          when Array
            obj.map { |v| deep_stringify_keys(v) }
          when Hash
            obj.each_with_object({}) do |(k, v), result|
              result[k.to_s] = deep_stringify_keys(v)
            end
          else
            obj
          end
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
