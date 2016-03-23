class RubeePass::Error::InvalidXML < RubeePass::Error
    def initialize
        super("Invalid xml schema!")
    end
end
