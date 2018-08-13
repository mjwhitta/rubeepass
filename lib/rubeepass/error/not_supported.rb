class RubeePass::Error::NotSupported < RubeePass::Error
    def initialize
        super("Encryption scheme not currently supported")
    end
end
