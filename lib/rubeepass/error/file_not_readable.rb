class RubeePass::Error::FileNotReadable < RubeePass::Error
    def initialize(file)
        super("File not readable: #{file}")
    end
end
