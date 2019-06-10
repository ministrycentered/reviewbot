require 'spec_helper'

describe ReviewBot::Reminder do
  context 'reminders' do
    before do
      JSON.parse(ENV['CONFIG']).each do |app, app_config|
        owner, repo = app.split('/')

        ReviewBot::HourOfDay.work_days = app_config['work_days']

        @reminder = ReviewBot::Reminder.new(owner, repo, app_config)
      end
    end

    it 'returns a reminder' do
      expect(@reminder).to be_a ReviewBot::Reminder
    end
  end

  describe '#notifications on non work days' do
    around do |example|
      Timecop.freeze(2018, 8, 31, 5, &example)
    end

    before do
      allow(ReviewConfig).to receive(:env_config).and_return(JSON.parse(config))

      allow_any_instance_of(Github::Client::PullRequests).to receive(:list).and_wrap_original do |m, *args|
        VCR.use_cassette('pull_requests') do
          m.call(*args)
        end
      end

      allow_any_instance_of(Github::Client::Issues).to receive(:get).and_wrap_original do |m, *args|
        VCR.use_cassette('issues') do
          m.call(*args)
        end
      end

      allow_any_instance_of(ReviewBot::PullRequest).to receive(:labels).and_return([])
      allow_any_instance_of(ReviewBot::PullRequest).to receive(:reviews).and_return([])

      allow_any_instance_of(ReviewBot::PullRequest).to receive(:needs_first_review?).and_return true
      allow_any_instance_of(ReviewBot::PullRequest).to receive(:ez?).and_return true
    end

    let(:config) do
      {'ministrycentered/reviewbot': {
        'notification_hours': [5, 13],
        'work_days': [1, 2, 3, 4],
        'room': 'reviewbot',
        'ignore_work_hours': ignore_work_hours,
        'hours_to_review': 0,
        'notify_in_progress_reviewers': false,
        'reviewers': [
          {
            "github": "danielma",
            "slack": "dma",
            "not_user_slack": "not_dma",
            "bamboohr": 1,
            "timezone": "America/Los_Angeles"
          },
          {
            "github": "awortham",
            "slack": "adubs",
            "not_user_slack": "not_adubs",
            "bamboohr": 1,
            "timezone": "America/Detroit"
          }
        ]
      }}.to_json
    end

    context 'ignore_work_hours' do
      context 'when ignore_work_hours is true' do
        let(:ignore_work_hours) { true }

        it 'does not send notifications' do
          expect(ReviewBot::Notification).to_not receive(:new)

          Rake::Task['remind'].invoke
        end
      end
    end
  end

  describe '#notifications' do
    around do |example|
      Timecop.freeze(2018, 8, 29, 5, &example)
    end

    before do
      allow(ReviewConfig).to receive(:env_config).and_return(JSON.parse(config))

      allow_any_instance_of(Github::Client::PullRequests).to receive(:list).and_wrap_original do |m, *args|
        VCR.use_cassette('pull_requests') do
          m.call(*args)
        end
      end

      allow_any_instance_of(Github::Client::Issues).to receive(:get).and_wrap_original do |m, *args|
        VCR.use_cassette('issues') do
          m.call(*args)
        end
      end

      allow_any_instance_of(ReviewBot::PullRequest).to receive(:labels).and_return([])
      allow_any_instance_of(ReviewBot::PullRequest).to receive(:reviews).and_return([])

      allow_any_instance_of(ReviewBot::PullRequest).to receive(:needs_first_review?).and_return true
      allow_any_instance_of(ReviewBot::PullRequest).to receive(:ez?).and_return true
    end

    let(:config) do
      {'ministrycentered/reviewbot': {
        'notification_hours': [5, 13],
        'room': 'reviewbot',
        'ignore_work_hours': ignore_work_hours,
        'hours_to_review': 0,
        'notify_in_progress_reviewers': false,
        'reviewers': [
          {
            "github": "danielma",
            "slack": "dma",
            "not_user_slack": "not_dma",
            "bamboohr": 1,
            "timezone": "America/Los_Angeles"
          },
          {
            "github": "awortham",
            "slack": "adubs",
            "not_user_slack": "not_adubs",
            "bamboohr": 1,
            "timezone": "America/Detroit"
          }
        ]
      }}.to_json
    end

    context 'ignore_work_hours' do
      context 'when ignore_work_hours is true' do
        let(:ignore_work_hours) { true }

        it 'sends notifications' do
          expect(ReviewBot::Notification).to receive(:new).exactly(3).times

          Rake::Task['remind'].invoke
        end
      end

      context 'when ignore_work_hours is false' do
        let(:ignore_work_hours) { false }

        it 'does not send notifications' do
          expect(ReviewBot::Notification).to_not receive(:new)

          Rake::Task['remind'].invoke
        end
      end
    end
  end
end
