require 'bcrypt'

module GrapeDeviseAuth
  module Concerns
    module User
      extend ActiveSupport::Concern

      def self.tokens_match?(token_hash, token)
        @token_equality_cache ||= {}

        key = "#{token_hash}/#{token}"
        result = @token_equality_cache[key] ||= (::BCrypt::Password.new(token_hash) == token)
        if @token_equality_cache.size > 10000
          @token_equality_cache = {}
        end
        result
      end

      included do
        # Hack to check if devise is already enabled
        unless self.method_defined?(:devise_modules)
          devise :database_authenticatable, :registerable,
              :recoverable, :trackable, :validatable, :confirmable
        else
          self.devise_modules.delete(:omniauthable)
        end

        unless tokens_has_json_column_type?
          serialize :tokens, JSON
        end

        # can't set default on text fields in mysql, simulate here instead.
        after_save :set_empty_token_hash
        after_initialize :set_empty_token_hash

        # get rid of dead tokens
        before_save :destroy_expired_tokens

        # remove old tokens if password has changed
        before_save :remove_tokens_after_password_reset

        # allows user to change password without current_password
        attr_writer :allow_password_change
        def allow_password_change
          @allow_password_change || false
        end

        # don't use default devise email validation
        def email_required?
          false
        end

        def email_changed?
          false
        end
      end


      module ClassMethods
        protected

        def tokens_has_json_column_type?
          table_exists? && self.columns_hash['tokens'] && self.columns_hash['tokens'].type.in?([:json, :jsonb])
        end
      end


      def build_auth_header(token, client_id='default')
        client_id ||= 'default'

        # client may use expiry to prevent validation request if expired
        # must be cast as string or headers will break
        expiry = self.tokens[client_id]['expiry'] || self.tokens[client_id][:expiry]

        max_clients = GrapeDeviseAuth.max_number_of_devices
        while self.tokens.keys.length > 0 and max_clients < self.tokens.keys.length
          oldest_token = self.tokens.min_by { |cid, v| v[:expiry] || v["expiry"] }
          self.tokens.delete(oldest_token.first)
        end

        self.save!

        return {
          GrapeDeviseAuth.headers_names[:"access-token"] => token,
          GrapeDeviseAuth.headers_names[:"token-type"]   => "Bearer",
          GrapeDeviseAuth.headers_names[:"client"]       => client_id,
          GrapeDeviseAuth.headers_names[:"expiry"]       => expiry.to_s,
          GrapeDeviseAuth.headers_names[:"uid"]          => self.uid
        }
      end

      def extend_batch_buffer(token, client_id)
        self.tokens[client_id]['updated_at'] = Time.now

        return build_auth_header(token, client_id)
      end

      def valid_token?(token, client_id='default')
        client_id ||= 'default'

        return false unless self.tokens[client_id]

        return true if token_is_current?(token, client_id)
        return true if token_can_be_reused?(token, client_id)

        # return false if none of the above conditions are met
        return false
      end

      def token_is_current?(token, client_id)
        # ghetto HashWithIndifferentAccess
        expiry     = self.tokens[client_id]['expiry'] || self.tokens[client_id][:expiry]
        token_hash = self.tokens[client_id]['token'] || self.tokens[client_id][:token]

        return true if (
          # ensure that expiry and token are set
          expiry and token and

          # ensure that the token has not yet expired
          DateTime.strptime(expiry.to_s, '%s') > Time.now and

          # ensure that the token is valid
          GrapeDeviseAuth::Concerns::User.tokens_match?(token_hash, token)
        )
      end

      # allow batch requests to use the previous token
      def token_can_be_reused?(token, client_id)
        # ghetto HashWithIndifferentAccess
        updated_at = self.tokens[client_id]['updated_at'] || self.tokens[client_id][:updated_at]
        last_token = self.tokens[client_id]['last_token'] || self.tokens[client_id][:last_token]


        return true if (
          # ensure that the last token and its creation time exist
          updated_at and last_token and

          # ensure that previous token falls within the batch buffer throttle time of the last request
          Time.parse(updated_at) > Time.now - GrapeDeviseAuth.batch_request_buffer_throttle and

          # ensure that the token is valid
          ::BCrypt::Password.new(last_token) == token
        )
      end

      # update user's auth token (should happen on each request)
      def create_new_auth_token(client_id=nil)
        client_id  ||= SecureRandom.urlsafe_base64(nil, false)
        last_token ||= nil
        token        = SecureRandom.urlsafe_base64(nil, false)
        token_hash   = ::BCrypt::Password.create(token)
        expiry       = (Time.now + GrapeDeviseAuth.token_lifespan).to_i

        if self.tokens[client_id] and self.tokens[client_id]['token']
          last_token = self.tokens[client_id]['token']
        end

        self.tokens[client_id] = {
          token:      token_hash,
          expiry:     expiry,
          last_token: last_token,
          updated_at: Time.now
        }
        
        return build_auth_header(token, client_id)
      end

      protected

      def set_empty_token_hash
        self.tokens ||= {} if has_attribute?(:tokens)
      end

      def destroy_expired_tokens
        if self.tokens
          self.tokens.delete_if do |cid, v|
            expiry = v[:expiry] || v["expiry"]
            DateTime.strptime(expiry.to_s, '%s') < Time.now
          end
        end
      end

      def remove_tokens_after_password_reset
        there_is_more_than_one_token = self.tokens && self.tokens.keys.length > 1
        should_remove_old_tokens = GrapeDeviseAuth.remove_tokens_after_password_reset &&
                                   encrypted_password_changed? && there_is_more_than_one_token

        if should_remove_old_tokens
          latest_token = self.tokens.max_by { |cid, v| v[:expiry] || v["expiry"] }
          self.tokens = { latest_token.first => latest_token.last }
        end
      end
    end
  end
end