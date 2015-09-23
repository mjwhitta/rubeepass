require "rubeepass/error"

class RubeePass::Error::InvalidProtectedDataError < RubeePass::Error
    def initialize
        super("Invalid protected data!")
    end
end
