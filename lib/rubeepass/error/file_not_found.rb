class RubeePass::Error::FileNotFound < RubeePass::Error
    def initialize(file)
        super("File not found: #{file}")
    end
end
