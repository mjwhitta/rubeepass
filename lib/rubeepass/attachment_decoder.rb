require "base64"
require "rexml/document"
require "zlib"

class RubeePass::AttachmentDecoder
    def get_attachment(ref)
        @binaries.elements.each("Binary") do |elem|
            if (elem.attributes["ID"] == ref)
                if (elem.attributes["Compressed"].nil?)
                    begin
                        return Base64.decode64(elem.text)
                    rescue
                        return elem.text
                    end
                end
                return parse_gzip(elem.text)
            end
        end
    end

    def initialize(binaries)
        @binaries = binaries
    end

    def parse_gzip(attachment)
        begin
            attachment = Base64.decode64(attachment)
        rescue
            # Do nothing
        end
        return Zlib::GzipReader.new(StringIO.new(attachment)).read
    end
    private :parse_gzip
end
