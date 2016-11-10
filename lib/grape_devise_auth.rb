%w(version middleware auth_helpers authorizer_data errors/unauthorized
   token_authorizer configuration auth_headers devise_interface concerns/user
   errors/login_failed errors/logout_failed errors/registration_failed).each  do |file|
     require "grape_devise_auth/#{file}"
   end

require 'grape'

module GrapeDeviseAuth
  class << self
    extend Forwardable

    def_delegators :configuration,
                   :batch_request_buffer_throttle,
                   :change_headers_on_each_request,
                   :default_provider,
                   :token_lifespan,
                   :max_number_of_devices,
                   :headers_names,
                   :remove_tokens_after_password_reset

    def configuration
      @configuration ||= Configuration.new
    end

    def config
      yield(configuration)
    end

    def setup!(middleware = false)
      yield(configuration) if block_given?
      add_auth_strategy
    end

    def add_auth_strategy
      Grape::Middleware::Auth::Strategies.add(
        :grape_devise_auth,
        GrapeDeviseAuth::Middleware,
        ->(options) { [options[:resource_class]] }
      )
    end
  end
end