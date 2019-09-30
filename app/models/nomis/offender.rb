# frozen_string_literal: true

module Nomis
  class Offender < OffenderBase
    include Deserialisable

    attr_accessor :gender,
                  :latest_booking_id,
                  :main_offence,
                  :nationalities,
                  :noms_id,
                  :reception_date

    attr_reader :prison_id

    def initialize(fields = nil)
      # Allow this object to be reconstituted from a hash, we can't use
      # from_json as the one passed in will already be using the snake case
      # names whereas from_json is expecting the elite2 camelcase names.
      fields.each { |k, v| instance_variable_set("@#{k}", v) } if fields.present?
    end

    def self.from_json(payload)
      Offender.new.tap { |obj|
        obj.load_from_json(payload)
      }
    end

    def load_from_json(payload)
      @gender = payload['gender']
      @latest_booking_id = payload['latestBookingId']&.to_i
      @main_offence = payload['mainOffence']
      @nationalities = payload['nationalities']
      @noms_id = payload['nomsId']
      @prison_id = payload['latestLocationId']
      @reception_date = deserialise_date(payload, 'receptionDate')

      super(payload)
    end
  end
end
