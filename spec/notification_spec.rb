require 'spec_helper'

describe ReviewBot::Notification do
  before do
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

    allow_any_instance_of(ReviewBot::PullRequest).to receive(:needs_first_review?).and_return true
    allow_any_instance_of(ReviewBot::PullRequest).to receive(:ez?).and_return true
  end

  let(:pull_requests) { GH.pulls.list(@owner, @repo).body }
  let(:pull) { ReviewBot::PullRequest.new(pull_requests.last) }
  let(:suggested_reviewers) { [ ReviewBot::Reviewer.new(@app_config['reviewers'].first) ] }
  let(:completed_reviewers) { [ ReviewBot::Reviewer.new(@app_config['reviewers'].last) ] }
  let(:template) { }
  let(:config) do
      {'ministrycentered/reviewbot': {
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
            "timezone": "America/Los_Angeles"
          }
        ]
      }}.to_json
    end

  subject do
    ReviewBot::Notification.new(
      pull_request: pull,
      suggested_reviewers: suggested_reviewers,
      completed_reviewers: completed_reviewers,
      author: suggested_reviewers.first,
      template: template
    )
  end

  describe 'liquid message' do
    let(:template) { '{{bullet}} #{{pull_request_number}} needs a *{{needed_review_type}}* from {{suggested_emojis}}' }

    it 'returns a message' do
      expect(subject.message).to eq "• #1 needs a *first review* from :dma:"
    end

    describe 'filters' do
      let(:template) { '{{pull_request_title | truncate: 4, ".."}}' }

      it 'handles filters' do
        expect(subject.message).to eq "bo.."
      end
    end
  end

  describe 'default message' do
    it 'returns a message' do
      expect(subject.message).to eq "• #1 <https://github.com/ministrycentered/reviewbot/pull/1|bogus> needs a *first review* from :dma:"
    end
  end

  describe '#custom options' do
    context 'template' do
      let(:template) { '{{bullet}} #{{pull_request_number}} needs a *{{needed_review_type}}* from {{suggested_emojis}}' }

      it 'returns a message' do
        expect(subject.message).to eq "• #1 needs a *first review* from :dma:"
      end
    end
  end
end
