require 'spec_helper'

describe ReviewBot::Reminder do
  context 'sanity' do
    before do
      JSON.parse(ENV['CONFIG']).each do |app, app_config|
        owner, repo = app.split('/')

        puts "#{owner}/#{repo}"

        ReviewBot::HourOfDay.work_days = app_config['work_days']

        @reminder = ReviewBot::Reminder.new(owner, repo, app_config)
      end
    end

    it 'returns a reminder' do
      expect(@reminder).to be_a ReviewBot::Reminder
    end
  end

  describe '#messages' do
    around do |example|
      Timecop.freeze(2018, 8, 29, 5, &example)
    end

    before do
      ENV['CONFIG'] = config
      Rake.application.init
      Rake.application.load_rakefile

      JSON.parse(config).each do |app, app_config|
        @owner, @repo = app.split('/')
        @app_config = app_config
      end

      GH = Github.new(oauth_token: ENV['GH_AUTH_TOKEN'])

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
        'ignore_work_hours': false,
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
      it 'gives me sanity' do
        expect(STDOUT).to receive <~~MESSAGE
          Delivering a message to reviewbot
        MESSAGE

        Rake::Task['remind'].invoke
      end
    end
  end
end
