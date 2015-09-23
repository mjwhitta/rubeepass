require "rubeepass/error"

class RubeePass::Error::InvalidHeaderError < RubeePass::Error
    def initialize
        super("Invalid header format!")
    end
end
