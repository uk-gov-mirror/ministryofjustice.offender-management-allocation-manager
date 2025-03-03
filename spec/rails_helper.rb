# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
require 'spec_helper'
require 'support/helpers/api_helper'
require 'support/helpers/jwt_helper'
require 'support/helpers/features_helper'
require 'support/helpers/auth_helper'
require 'support/helpers/api_helper'
require 'support/matchers/responsibility_matchers'
require 'capybara/rspec'
require 'webmock/rspec'

Capybara.default_max_wait_time = 4
Capybara.asset_host = 'http://localhost:3000'

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

OmniAuth.config.test_mode = true

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.use_transactional_fixtures = false
  config.example_status_persistence_file_path = 'tmp/example_status.txt'
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each, :js) do
    page.driver.browser.manage.window.resize_to(1280,3072)
  end

  config.before(:each, :disable_push_to_delius) do
    # Stub the pushing of handover dates to the Community API
    # Useful when running ProcessDeliusDataJob, which attempts to push to the Community API
    allow(HmppsApi::CommunityApi).to receive(:set_handover_dates)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.include ActiveSupport::Testing::TimeHelpers
  config.include JWTHelper
  config.include FeaturesHelper
  config.include AuthHelper
  config.include ApiHelper

  config.before(:each, type: :view) do
    # This is needed for any view test that uses the sort_link and sort_arrow helpers
    # taken from https://github.com/bootstrap-ruby/rails-bootstrap-navbar/issues/15
    allow_any_instance_of(ActionController::TestRequest).to receive(:original_url).and_return('')
  end

  config.around(:each, :queueing) do |example|
    ActiveJob::Base.queue_adapter.tap do |adapter|
      ActiveJob::Base.queue_adapter = :test
      example.run
      ActiveJob::Base.queue_adapter = adapter
    end
  end

  # disallow connection to T3 by default
  # (using stubs hopefully generated by WebMock)
  WebMock.disable_net_connect!(allow_localhost: true)

  # in VCR mode, allow HTTP connections to T3, but then
  # reset back to default afterwards
  config.around(:each, :vcr) do |example|
    WebMock.allow_net_connect!
    example.run
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  # This is to prevent most tests from having to mock this callback due
  # to an after_save call back in Allocation. Enable by setting
  # the push_pom_to_delius tag in your tests
  config.before(:each, type: lambda { |_v, m| m[:push_pom_to_delius] != true } ) do
    allow(PushPomToDeliusJob).to receive(:perform_later)
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Set the locale for Faker gem to en-GB
# The en-GB locale gives us UK counties (used by the LocalDeliveryUnit factory)
# See all the things we gain here: https://github.com/faker-ruby/faker/blob/master/lib/locales/en-GB.yml
Faker::Config.locale = 'en-GB'
