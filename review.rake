# frozen_string_literal: true
require 'json'
require 'active_support/time'

CONFIG = JSON.parse(ENV['CONFIG'])
SLACK_TOKEN    = ENV['SLACK_TOKEN']
SLACK_BOT_NAME = 'reviewbot'
SLACK_BOT_ICON = ':robot_face:'

require_relative 'lib/review_bot'

desc 'Send reminders to team members to review PRs'
task :remind, [:mode] do |_t, args|
  dry_run = args[:mode] == 'dry'

  puts "-- DRY RUN --\n\n" if dry_run

  CONFIG.each do |app, app_config|
    if app_config['hours_to_review'].to_i == 0
      config_hours = app_config['notification_hours']
      raise 'notification hours required' if config_hours.nil?

      time_zone = app_config['notification_time_zone']
      current_hour = Time.current.in_time_zone(time_zone).hour

      next unless dry_run || config_hours.include?(current_hour)
    end

    owner, repo = app.split('/')
    room = app_config['room']

    puts "#{owner}/#{repo}"

    ReviewBot::HourOfDay.work_days = app_config['work_days']

    messages = ReviewBot::Reminder.new(owner, repo, app_config).messages
    messages.each do |message|

      puts

      next if message.nil?

      if dry_run
        puts "Would deliver message to #{room}"
        puts message
        puts
      else
        puts "Delivering a message to #{room}"

        RestClient.post(
          'https://slack.com/api/chat.postMessage',
          token: SLACK_TOKEN,
          channel: room,
          text: message,
          icon_emoji: SLACK_BOT_ICON,
          username: SLACK_BOT_NAME
        )
      end
    end
  end
end
