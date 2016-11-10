module GrapeDeviseAuth
  module AuthHelpers
    def self.included(_base)
      Devise.mappings.keys.each do |mapping|
        define_method("current_#{mapping}") do
          warden.user(mapping)
        end

        define_method("authenticate_#{mapping}") do
          @authorizer_data  = AuthorizerData.from_env(env)
          devise_interface = DeviseInterface.new(@authorizer_data)
          token_authorizer = TokenAuthorizer.new(@authorizer_data,
                                                 devise_interface)

          resource = token_authorizer.authenticate_from_token(mapping)
          if resource
            devise_interface.set_user_in_warden(mapping, resource)
            env[Configuration::CURRENT_AUTH_HEADERS] = AuthHeaders.new(warden,
                                                                       mapping,
                                                                       env[Configuration::REQUEST_START],
                                                                       @authorizer_data).headers
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
            env[Configuration::CURRENT_AUTH_HEADERS] = resource.create_new_auth_token
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

          env[Configuration::CURRENT_AUTH_HEADERS] = resource.create_new_auth_token if resource.save
          resource
        end

        define_method("register_#{mapping}!") do
          register = send("register_#{mapping}")
          raise RegistrationFailed.new(register.errors) if register.errors.any?
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
  end
end
