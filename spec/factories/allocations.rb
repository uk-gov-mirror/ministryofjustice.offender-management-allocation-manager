require 'faker'

FactoryBot.define do
  factory :allocation do
    allocated_at_tier do
      'A'
    end

    created_by_name do
      # The last name is titleized after it's received from the API, e.g. "McDonald" becomes "Mcdonald"
      # So we also .titleize the last name here to avoid breaking tests
      "#{Faker::Name.first_name} #{Faker::Name.last_name.titleize}"
    end

    event do
      Allocation::ALLOCATE_PRIMARY_POM
    end

    event_trigger do
      Allocation::USER
    end

    nomis_offender_id do
      Faker::Alphanumeric.alpha(number: 10)
    end

    primary_pom_nomis_id do
      485_926
      # using fake POM numbers tends to cause crashes
      # Faker::Number.number(digits: 7)
    end

    primary_pom_name do
      # The last name is titleized after it's received from the API, e.g. "McDonald" becomes "Mcdonald"
      # So we also .titleize the last name here to avoid breaking tests
      "#{Faker::Name.last_name.titleize}, #{Faker::Name.first_name}"
    end

    primary_pom_allocated_at do
      DateTime.now.utc
    end

    prison do
      'LEI'
    end

    updated_at do
      DateTime.now.utc
    end

    trait :primary do
      event {Allocation::ALLOCATE_PRIMARY_POM}
      event_trigger { Allocation::USER }
      primary_pom_nomis_id { 123_456}
      # The last name is titleized after it's received from the API, e.g. "McDonald" becomes "Mcdonald"
      # So we also .titleize the last name here to avoid breaking tests
      primary_pom_name {"#{Faker::Name.last_name.titleize}, #{Faker::Name.first_name}"}
      secondary_pom_nomis_id { nil }
      secondary_pom_name { nil }
    end

    trait :co_working do
      event {Allocation:: ALLOCATE_SECONDARY_POM}
      event_trigger { Allocation::USER }
      primary_pom_nomis_id {345_456}
      # The last name is titleized after it's received from the API, e.g. "McDonald" becomes "Mcdonald"
      # So we also .titleize the last name here to avoid breaking tests
      primary_pom_name {"#{Faker::Name.last_name.titleize}, #{Faker::Name.first_name}"}
      secondary_pom_nomis_id {234_567}
      secondary_pom_name {"#{Faker::Name.last_name.titleize}, #{Faker::Name.first_name}"}
    end

    trait :release do
      event { Allocation::DEALLOCATE_RELEASED_OFFENDER }
      event_trigger {Allocation::OFFENDER_RELEASED}
      primary_pom_nomis_id { nil}
      primary_pom_name { nil }
      secondary_pom_nomis_id { nil }
      secondary_pom_name { nil }
    end

    trait :transfer do
      event { Allocation::DEALLOCATE_PRIMARY_POM }
      event_trigger {Allocation::OFFENDER_RELEASED}
      primary_pom_nomis_id { nil}
      primary_pom_name { nil }
      secondary_pom_nomis_id { nil }
      secondary_pom_name { nil }
    end

    trait :reallocation do
      event {Allocation::REALLOCATE_PRIMARY_POM}
      event_trigger { Allocation::USER }
      primary_pom_nomis_id { 123_456}
      # The last name is titleized after it's received from the API, e.g. "McDonald" becomes "Mcdonald"
      # So we also .titleize the last name here to avoid breaking tests
      primary_pom_name {"#{Faker::Name.last_name.titleize}, #{Faker::Name.first_name}"}
      secondary_pom_nomis_id { nil }
      secondary_pom_name { nil }
    end

    trait :override do
      override_detail {Faker::Lorem.sentence}
      suitability_detail {Faker::Lorem.sentence}
      override_reasons { ["suitability"] }
    end
  end
end
