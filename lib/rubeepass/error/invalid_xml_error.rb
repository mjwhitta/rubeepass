require "rubeepass/error"

class RubeePass::Error::InvalidXMLError < RubeePass::Error
    def initialize
        super("Invalid xml schema!")
    end
end
