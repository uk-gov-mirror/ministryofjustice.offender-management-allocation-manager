# frozen_string_literal: true

FactoryBot.define do
  factory :offender_base, class: 'HmppsApi::OffenderBase' do
    # cell location is the format <1 letter>-<1 number>-<3 numbers> e.g 'E-4-014'
    internalLocation {
      block = Faker::Alphanumeric.alpha(number: 1).upcase
      num = Faker::Number.non_zero_digit
      numbers = Faker::Number.leading_zero_number(digits: 3)
      "#{block}-#{num}-#{numbers}"
    }

    # offender numbers are of the form <letter><4 numbers><2 letters>
    sequence(:offenderNo) do |seq|
      number = seq / 26 + 1000
      letter = ('A'..'Z').to_a[seq % 26]
      # This and case_information should produce different values to avoid clashes
      "T#{number}O#{letter}"
    end

    sequence(:bookingId) { |x| x + 700_000 }
    convictedStatus { 'Convicted' }
    dateOfBirth { Date.new(1990, 12, 6).to_s }
    firstName { Faker::Name.first_name }
    # We have some issues with corrupting the display
    # of names containing Mc or Du :-(
    # also ensure uniqueness as duplicate last names can cause issues
    # in tests, as ruby sort isn't stable by default
    sequence(:lastName) { |c| "#{Faker::Name.last_name.titleize}_#{c}" }
    categoryCode { 'C' }
    recall {  false }

    sentence { association :sentence_detail }

    complexityLevel { 'medium' }

  end

  factory :offender, parent: :offender_base, class: 'HmppsApi::Offender' do
    initialize_with do
      HmppsApi::Offender.new(attributes.stringify_keys,
                             attributes.stringify_keys,
                             latest_temp_movement: nil,
                             complexity_level: attributes.fetch(:complexityLevel)).tap { |offender|
        offender.sentence = attributes.fetch(:sentence)
      }
    end

    latestLocationId { 'LEI' }

    trait :prescoed do
      latestLocationId { PrisonService::PRESCOED_CODE }
    end
  end

  factory :nomis_offender, class: Hash do
    initialize_with { attributes }

    currentlyInPrison { 'Y' }
    imprisonmentStatus { 'SENT03' }
    agencyId { 'LEI' }

    # cell location is the format <1 letter>-<1 number>-<3 numbers> e.g 'E-4-014'
    internalLocation {
      block = Faker::Alphanumeric.alpha(number: 1).upcase
      num = Faker::Number.non_zero_digit
      numbers = Faker::Number.leading_zero_number(digits: 3)
      "#{block}-#{num}-#{numbers}"
    }

    # offender numbers are of the form <letter><4 numbers><2 letters>
    sequence(:offenderNo) do |seq|
      number = seq / 26 + 1000
      letter = ('A'..'Z').to_a[seq % 26]
      # This and case_information should produce different values to avoid clashes
      "T#{number}O#{letter}"
    end
    convictedStatus { 'Convicted' }
    dateOfBirth { Date.new(1990, 12, 6).to_s }
    firstName { Faker::Name.first_name }
    # We have some issues with corrupting the display
    # of names containing Mc or Du :-(
    # also ensure uniqueness as duplicate last names can cause issues
    # in tests, as ruby sort isn't stable by default
    sequence(:lastName) { |c| "#{Faker::Name.last_name.titleize}_#{c}" }
    categoryCode { 'C' }
    recall { false }

    sentence do
      attributes_for :sentence_detail
    end

    complexityLevel { 'medium' }

    trait :indeterminate do
      imprisonmentStatus {'LIFE'}
      sentence { attributes_for(:sentence_detail, :indeterminate) }
    end

    # the default release date and conditional release date will force the offender to be POM supporting and requiring a COM
    # this trait makes sure the determinate offender has a release date long into the future
    trait :determinate_release_in_three_years do
      sentence { attributes_for(:sentence_detail, releaseDate: Time.zone.today + 3.years, conditionalReleaseDate: Time.zone.today + 3.years) }
    end

    sequence(:bookingId) { |c| c + 100_000 }
  end
end
