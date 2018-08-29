require 'spec_helper'

describe ReviewBot::BambooHR do
  let(:subject) { ReviewBot::BambooHR.new( api_key: '55555', subdomain: 'pco' ) }

  before do
    VCR.use_cassette(:bamboo_requests) do
     @reviews = subject.whos_out(start_date: Date.today)
    end
  end

  it 'returns an array of ids the same as the old whos_out endpoint' do
    expect(@reviews.map { |t| t['employeeId'] }).to eq ['40']
  end
end
