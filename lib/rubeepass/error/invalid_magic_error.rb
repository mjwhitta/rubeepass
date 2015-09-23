require "rubeepass/error"

class RubeePass::Error::InvalidMagicError < RubeePass::Error
    def initialize
        super("Invalid magic values detected!")
    end
end
