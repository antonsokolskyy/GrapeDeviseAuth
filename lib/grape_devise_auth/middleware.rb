module GrapeDeviseAuth
  class Middleware

    def initialize(app, resource_name)
      @app = app
      @resource_name = resource_name
    end

    def call(env)
      setup(env)
      responses_with_headers(*@app.call(env))
    end

    private

    def setup(env)
      env[Configuration::REQUEST_START] = Time.now
    end

    def responses_with_headers(status, headers, response)
      [ status, headers, response ]
    end
  end
end
