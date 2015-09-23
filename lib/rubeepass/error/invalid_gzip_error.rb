require "rubeepass/error"

class RubeePass::Error::InvalidGzipError < RubeePass::Error
    def initialize
        super("Invalid gzip format!")
    end
end
