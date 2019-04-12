# frozen_string_literal: true
module ReviewBot
  GH = Github.new do |config|
    config.oauth_token = ENV['GH_AUTH_TOKEN']
    config.connection_options = { headers: {'Accept' => 'application/vnd.github.shadow-cat-preview+json' } }
  end

  class Reminder
    attr_reader :owner, :repo, :app_config

    def initialize(owner, repo, app_config)
      @owner = owner
      @repo = repo
      @app_config = app_config
    end

    def message
      return if notifications.empty?
      notifications.map(&:message).join("\n")
    end

    def app_reviewers
      @app_reviewers ||= app_config['reviewers'].map { |r| Reviewer.new(r) }
    end

    def out_reviewers
      return @out_reviewers if defined?(@out_reviewers)
      return @out_reviewers = [] unless bamboo_hr

      @out_reviewers ||=
        begin
          whos_out_ids = bamboo_hr
                         .whos_out(start_date: Date.today)
                         .map { |t| t['employeeId'] }
          app_reviewers.select { |r| whos_out_ids.include? r.bamboohr }
        end
    end

    def bamboo_hr
      return @bamboo_hr if defined?(@bamboo_hr)

      @bamboo_hr ||=
        if app_config['bamboohr_subdomain']
          BambooHR.new(
            api_key: ENV['BAMBOOHR_API_KEY'],
            subdomain: app_config['bamboohr_subdomain']
          )
        end
    end

    def notifications
      @notifications ||= potential_notifications.compact
    end

    def sorted_pull_requests
      pulls = GH.pulls.list(owner, repo).body
      app_config['sort_asc'] ? pulls.reverse : pulls
    end

    def potential_notifications
      sorted_pull_requests.map do |p|
        pull = PullRequest.new(p, { notify_in_progress_reviewers: app_config['notify_in_progress_reviewers'] })

        print '.'

        next unless pull.needs_review?

        potential_reviewers = app_reviewers
                              .reject { |r| r.github == pull.user.login }
                              .reject { |r| out_reviewers.include? r }

        author = app_reviewers.detect { |r| r.github == pull.user.login } || Reviewer.new('slack' => pull.user.login)

        person_hours_since_last_touch = potential_reviewers.map do |reviewer|
          reviewer.work_hours_between(pull.last_touched_at, Time.now.utc)
        end.reduce(0, :+)

        next if person_hours_since_last_touch < app_config['hours_to_review']

        suggested_reviewers = potential_reviewers.reject do |reviewer|
          pull.reviewers.include?(reviewer['github'])
        end

        completed_reviewers = potential_reviewers - suggested_reviewers

        next if suggested_reviewers.select(&:work_hour?).empty?

        Notification.new(
          pull_request: pull,
          suggested_reviewers: suggested_reviewers,
          completed_reviewers: completed_reviewers,
          author: author,
          template: app_config['notification_template']
        )
      end
    end
  end
end
