require "rubeepass/error"

class RubeePass::Error::InvalidPasswordError < RubeePass::Error
    def initialize
        super("Invalid password provided!")
    end
end
