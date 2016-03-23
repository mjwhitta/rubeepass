class RubeePass::Error::InvalidPassword < RubeePass::Error
    def initialize
        super("Invalid password provided!")
    end
end
