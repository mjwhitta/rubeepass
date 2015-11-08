# Redefine String class to allow for colorizing, rsplit, and word wrap
class String
    def blue
        return colorize(36)
    end

    def colorize(color)
        return "\e[#{color}m#{self}\e[0m"
    end

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

    def green
        return colorize(32)
    end

    def red
        return colorize(31)
    end

    def rsplit(pattern)
        ret = rpartition(pattern)
        ret.delete_at(1)
        return ret
    end

    def white
        return colorize(37)
    end

    def word_wrap(width = 70)
        return scan(/\S.{0,#{width}}\S(?=\s|$)|\S+/).join("\n")
    end
end
