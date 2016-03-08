require "rubeepass/error"

class RubeePass::Error::InvalidMagic < RubeePass::Error
    def initialize
        super("Invalid magic values detected!")
    end
end
