require "rubeepass/error"

class RubeePass::Error::InvalidProtectedStreamKey < RubeePass::Error
    def initialize
        super("Invalid protected stream key!")
    end
end
