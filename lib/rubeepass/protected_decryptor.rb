require "salsa20"

class RubeePass::ProtectedDecryptor
    def add_to_stream(str)
        @ciphertext.push(str)
        return (@ciphertext.length - 1)
    end

    def get_password(index)
        return nil if (@iv.nil? || @key.nil?)
        return nil if ((index < 0) || (index >= @ciphertext.length))

        plaintext = Salsa20.new(@key, @iv).decrypt(@ciphertext.join)

        start = 0
        index.times do |i|
            start += @ciphertext[i].length
        end

        stop = start + @ciphertext[index].length

        return plaintext[start...stop]
    end

    def initialize(key, iv)
        @ciphertext = Array.new
        @iv = iv
        @key = key
    end
end
