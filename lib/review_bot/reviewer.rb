# frozen_string_literal: true
module ReviewBot
  class Reviewer < OpenStruct
    def work_hours_between(start_time, end_time)
      HourOfDay.work_hours_between(start_time, end_time, timezone)
    end

    def timezone
      Timezone[@table[:timezone]]
    end

    def work_hour?
      HourOfDay.new(timezone.utc_to_local(Time.now.utc)).work_hour?
    end

    def slack_emoji
      ":#{slack}:"
    end

    def not_user_slack_emoji
      not_user_slack.nil? ? ":not_#{slack}:" : ":#{not_user_slack}:"
    end
  end
end
