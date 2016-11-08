module GrapeDeviseAuth
  module AuthHelpers
    def self.included(_base)
      Devise.mappings.keys.each do |mapping|
        define_method("current_#{mapping}") do
          warden.user(mapping)
        end

        define_method("authenticate_#{mapping}") do
          load_auth_headers_data(mapping)
          authorizer_data  = AuthorizerData.from_env(env)
          devise_interface = DeviseInterface.new(authorizer_data)
          token_authorizer = TokenAuthorizer.new(authorizer_data,
                                                 devise_interface)

          resource = token_authorizer.authenticate_from_token(mapping)
          if resource
            devise_interface.set_user_in_warden(mapping, resource)
            update_expiry_for_client_token(authorizer_data.client_id)
            true
          end
        end

        define_method("authenticate_#{mapping}!") do
          authentication = send("authenticate_#{mapping}")
          raise Unauthorized unless authentication
          authentication
        end

        define_method("login_#{mapping}") do
          field = authentication_field(mapping)
          uid = find_uid(field)
          resource = resource_class(mapping).find_by_uid(uid)

          if resource && valid_params?(field, uid) && resource.valid_password?(params[:password]) && (!resource.respond_to?(:active_for_authentication?) || resource.active_for_authentication?)
            update_env_with_auth_data(resource.create_new_auth_token)
            warden.set_user(resource, scope: mapping, store: false)
          end
        end

        define_method("login_#{mapping}!") do
          login = send("login_#{mapping}")
          raise LoginFailed unless login
          login
        end

        define_method("logout_#{mapping}") do
          resource = warden.user(mapping)
          client_id = env[Configuration::CLIENT_KEY]
          warden.logout
          if resource && client_id && resource.tokens[client_id]
            resource.tokens.delete(client_id)
            resource.save!
          else
            nil
          end
        end

        define_method("logout_#{mapping}!") do
          logout = send("logout_#{mapping}")
          raise LogoutFailed unless logout
          logout
        end

        define_method("#{mapping}_auth_headers") do
          env[Configuration::CURRENT_AUTH_HEADERS]
        end

        define_method("register_#{mapping}") do
          resource = resource_class(mapping).new(declared(params))
          resource.provider = GrapeDeviseAuth.default_provider

          if resource_class(mapping).case_insensitive_keys.include?(:email)
            resource.email = declared(params)['email'].try :downcase
          end

          if resource.save
            update_env_with_auth_data(resource.create_new_auth_token)
          else
            nil
          end
        end

        define_method("register_#{mapping}!") do
          register = send("register_#{mapping}")
          raise RegistrationFailed unless register
          register
        end
      end
    end

    def warden
      @warden ||= env['warden']
    end

    def authenticated?(scope = :user)
      user_type = "current_#{scope}"
      return false unless respond_to?(user_type)
      !!send(user_type)
    end

    private

    def valid_params?(key, val)
      params[:password] && key && val
    end

    def resource_class(m = nil)
      mapping = if m
                  Devise.mappings[m]
                else
                  Devise.mappings[resource_name] || Devise.mappings.values.first
                end
      mapping.to
    end

    def authentication_field(mapping)
      field = (params.keys.map(&:to_sym) && resource_class(mapping).authentication_keys).first
    end

    def find_uid(field)
      request.headers[field.to_s.capitalize] || params[field] || request.headers['Uid'] || params['uid']
    end

    def load_auth_headers_data(mapping)
      env[Configuration::UID_KEY] = find_uid(authentication_field(mapping))
      env[Configuration::CLIENT_KEY] = request.headers['Client'] || params['client']
      env[Configuration::ACCESS_TOKEN_KEY] = request.headers['Access-Token'] || params['access-token']
    end

    def update_expiry_for_client_token(client_id)
      if @user
        @client_id = client_id
        @user.tokens[@client_id]['expiry'] = (Time.now + GrapeDeviseAuth.token_lifespan).to_i
        @user.save
      end
    end

    def update_env_with_auth_data(auth_data)
      env[Configuration::CURRENT_AUTH_HEADERS] = auth_data
    end
  end
end
