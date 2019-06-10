# frozen_string_literal: true
module ReviewBot
  class Reviewer < OpenStruct
    attr_reader :hour_of_day

    def initialize(r)
      super
      @hour_of_day = HourOfDay.new(timezone.utc_to_local(Time.now.utc))
    end

    def work_hours_between(start_time, end_time)
      HourOfDay.work_hours_between(start_time, end_time, timezone)
    end

    def timezone
      Timezone[@table[:timezone]]
    end

    def work_hour?
      hour_of_day.work_hour?
    end

    def work_day?
      hour_of_day.work_day?
    end

    def slack_emoji
      ":#{slack}:"
    end

    def not_user_slack_emoji
      not_user_slack.nil? ? ":not_#{slack}:" : ":#{not_user_slack}:"
    end
  end
end
