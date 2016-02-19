# Modify String class to allow for rsplit and word wrap
class String
    def fix
        # Fix unicode (I think???)
        # Apparently sometimes length and bytesize don't always agree.
        # When this happens, there are "invisible" bytes, which I need
        # to be "visible". Converting to hex and back fixes this.
        if (length != bytesize)
            return self.unpack("H*").pack("H*")
        end
        return self
    end

    def rsplit(pattern)
        ret = rpartition(pattern)
        ret.delete_at(1)
        return ret
    end

    def word_wrap(width = 80)
        return scan(/\S.{0,#{width}}\S(?=\s|$)|\S+/).join("\n")
    end
end
