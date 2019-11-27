# frozen_string_literal: true

require 'base64'

module Nomis
  module Oauth
    class Token
      include Deserialisable

      attr_accessor :access_token,
                    :token_type,
                    :expires_in,
                    :scope,
                    :internal_user,
                    :jti,
                    :auth_source

      def initialize(fields = nil)
        # Allow this object to be reconstituted from a hash, we can't use
        # from_json as the one passed in will already be using the snake case
        # names whereas from_json is expecting the elite2 camelcase names.
        fields.each { |k, v| instance_variable_set("@#{k}", v) } if fields.present?
      end

      def expired?
        x = payload.fetch('exp')
        expiry_seconds = Time.zone.at(x) - Time.zone.now
        # consider token expired if it has less than 10 seconds to go
        expiry_seconds < 10
      rescue JWT::ExpiredSignature => e
        Raven.capture_exception(e)
        true
      end

      def valid_token_with_scope?(scope)
        return false if payload['scope'].nil?
        return false unless payload['scope'].include? scope

        true
      rescue JWT::DecodeError, JWT::ExpiredSignature => e
        Raven.capture_exception(e)
        false
      end

      def payload
        @payload ||= JWT.decode(
          access_token,
          OpenSSL::PKey::RSA.new(public_key),
          true,
          algorithm: 'RS256'
        ).first
      end

      def self.from_json(payload)
        Token.new.tap { |obj|
          obj.access_token = payload['access_token']
          obj.token_type = payload['token_type']
          obj.expires_in = payload['expires_in']
          obj.scope = payload['scope']
          obj.internal_user = payload['internal_user']
          obj.jti = payload['jti']
          obj.auth_source = payload['auth_source']
        }
      end

    private

      def public_key
        @public_key ||= Base64.urlsafe_decode64(
          Rails.configuration.nomis_oauth_public_key
        )
      end
    end
  end
end
