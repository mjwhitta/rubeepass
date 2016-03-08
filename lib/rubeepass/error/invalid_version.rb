require "rubeepass/error"

class RubeePass::Error::InvalidVersion < RubeePass::Error
    def initialize
        super("Invalid version detected!")
    end
end
