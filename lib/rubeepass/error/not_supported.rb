class RubeePass::Error::NotSupported < RubeePass::Error
    def initialize(msg = nil)
        if (msg.nil?)
            super("Encryption scheme not currently supported")
        else
            super("Encryption scheme not currently supported: #{msg}")
        end
    end
end
