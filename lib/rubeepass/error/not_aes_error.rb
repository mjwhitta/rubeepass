require "rubeepass/error"

class RubeePass::Error::NotAESError < RubeePass::Error
    def initialize
        super("Not AES!")
    end
end
