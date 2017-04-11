require "rexml/document"
require "zlib"

class RubeePass::AttachmentDecoder
    def find_attachment(ref)
        @binaries.elements.each("Binary") do |elem|
            if elem.attributes["ID"] == ref
                return elem.text
            end
        end
    end
    private :find_attachment

    def get_attachment(ref)
        attachment = find_attachment(ref)
        return parse_gzip(attachment)
    end

    def initialize(binaries)
        @binaries = binaries
    end

    def parse_gzip(attachment)
        attachment = attachment.unpack("m*")[0]
        return Zlib::GzipReader.new(StringIO.new(attachment)).read
    end
    private :parse_gzip
end
