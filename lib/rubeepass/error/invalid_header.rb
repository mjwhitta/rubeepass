class RubeePass::Error::InvalidHeader < RubeePass::Error
    def initialize(msg = nil)
        if (msg.nil?)
            super("Invalid header format!")
        else
            super("Invalid header: #{msg}")
        end
    end
end
