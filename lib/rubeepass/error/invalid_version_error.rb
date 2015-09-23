require "rubeepass/error"

class RubeePass::Error::InvalidVersionError < RubeePass::Error
    def initialize
        super("Invalid version detected!")
    end
end
