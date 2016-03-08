require "rubeepass/error"

class RubeePass::Error::InvalidProtectedData < RubeePass::Error
    def initialize
        super("Invalid protected data!")
    end
end
