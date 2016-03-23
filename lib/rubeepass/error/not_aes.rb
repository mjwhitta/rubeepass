class RubeePass::Error::NotAES < RubeePass::Error
    def initialize
        super("Not AES!")
    end
end
