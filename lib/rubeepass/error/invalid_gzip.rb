require "rubeepass/error"

class RubeePass::Error::InvalidGzip < RubeePass::Error
    def initialize
        super("Invalid gzip format!")
    end
end
