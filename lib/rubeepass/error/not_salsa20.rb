require "rubeepass/error"

class RubeePass::Error::NotSalsa20 < RubeePass::Error
    def initialize
        super("Not a Salsa20 CrsAlgorithm!")
    end
end
