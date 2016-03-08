require "rubeepass/error"

class RubeePass::Error::InvalidHeader < RubeePass::Error
    def initialize
        super("Invalid header format!")
    end
end
