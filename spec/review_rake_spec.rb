require 'spec_helper'

describe 'rake remind' do
  around do |example|
    Timecop.freeze(2019, 04, 15, 9, &example)
  end

  before do
    allow(ReviewConfig).to receive(:env_config).and_return(JSON.parse(config))
  end

  context 'when one app should run and the other should not' do
    let(:config) do
      {
        'ministrycentered/reviewbot': {
          'notification_hours': [10, 13],
          "notification_time_zone": "America/Los_Angeles"
        },
        'ministrycentered/fake_app': {
          'notification_hours': [9, 13],
          "notification_time_zone": "America/Los_Angeles"
        },
        'ministrycentered/hours_to_review': {
          'hours_to_review': 3
        }
      }.to_json
    end

    it 'only runs for the app with the matching hour' do
      allow_any_instance_of(ReviewBot::Reminder).to receive(:messages).and_return []
      allow(RestClient).to receive(:post).and_return true

      expect(ReviewBot::HourOfDay).to receive(:work_days=).twice.and_call_original
      Rake::Task['remind'].invoke
    end
  end
end
