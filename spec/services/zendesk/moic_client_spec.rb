require 'rails_helper'

RSpec.describe Zendesk::MOICClient do
  subject { described_class.instance }

  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  before do
    ENV['ZENDESK_URL'] = 'https://zendesk_api.com'
    ENV['ZENDESK_USERNAME'] = "bob"
    ENV['ZENDESK_TOKEN'] = "123456"
  end

  describe 'a valid instance' do
    it 'has a zendesk url' do
      subject.request { |client| expect(client.config.url).to eq(url) }
    end

    it 'has a zendesk username' do
      subject.request { |client| expect(client.config.username).to eq("#{username}/token") }
    end

    it 'has a zendesk token' do
      subject.request { |client| expect(client.config.token).to eq(token) }
    end
  end

  describe '#request' do
    let(:pool) { double(ConnectionPool) }
    let(:block) do
      ->(_) {}
    end

    before do
      allow(ConnectionPool).to receive(:new).and_return(pool)
    end

    it 'yields the give block passing an instance of zendesk client' do
      expect(pool).to receive(:with).and_yield(instance_of(ZendeskAPI::Client))
      subject.request(&block)
    end
  end
end
