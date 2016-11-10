module GrapeDeviseAuth
  class Configuration
    attr_accessor :batch_request_buffer_throttle,
                  :change_headers_on_each_request,
                  :default_provider,
                  :token_lifespan,
                  :max_number_of_devices,
                  :headers_names,
                  :remove_tokens_after_password_reset

    ACCESS_TOKEN_KEY = 'HTTP_ACCESS_TOKEN'
    EXPIRY_KEY = 'HTTP_EXPIRY'
    UID_KEY = 'HTTP_UID'
    CLIENT_KEY = 'HTTP_CLIENT'
    REQUEST_START = 'REQUEST_START'
    CURRENT_AUTH_HEADERS = 'CURRENT_AUTH_HEADERS'

    def initialize
      @batch_request_buffer_throttle = 2.weeks
      @change_headers_on_each_request = true
      @default_provider = 'email'
      @token_lifespan = 2.weeks
      @max_number_of_devices = 10
      @headers_names = {:'access-token' => 'access-token',
                        :'client' => 'client',
                        :'expiry' => 'expiry',
                        :'uid' => 'uid',
                        :'token-type' => 'token-type' }
      @remove_tokens_after_password_reset = false
    end
  end
end
