require "rubeepass/error"

class RubeePass::Error::InvalidProtectedStreamKeyError < RubeePass::Error
    def initialize
        super("Invalid protected stream key!")
    end
end
