module GrapeDeviseAuth
  class RegistrationFailed < StandardError
    def initialize(errors = nil)
      @errors = errors
    end

    def errors
      @errors
    end
  end
end
