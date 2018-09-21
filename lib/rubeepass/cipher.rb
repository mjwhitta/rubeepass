require "openssl"
require "twofish"

class RubeePass::Cipher
    # Encryption schemes
    module ID
        AES = "31c1f2e6bf714350be5805216afc5aff"
        CHACHA20 = "d6038a2b8b6f4cb5a524339a31dbb59a"
        TWOFISH = "ad68f29f576f4bb9a36ad47af965346c"
    end

    def decrypt(enc)
        # Setup
        case @id
        when ID::AES
            cipher = OpenSSL::Cipher::AES.new(256, :CBC)
        when ID::CHACHA20
            cipher = OpenSSL::Cipher.new("chacha20")
        when ID::TWOFISH
            cipher = Twofish.new(
                @key,
                {
                    :iv => @iv,
                    :mode => :cbc,
                    :padding => :none
                }
            )
        else
            raise RubeePass::Error::NotSupported.new
        end

        # Decrypt
        case @id
        when ID::AES, ID::CHACHA20
            begin
                cipher.decrypt
                cipher.key = @key
                cipher.iv = @iv
                return StringIO.new(cipher.update(enc) + cipher.final)
            rescue OpenSSL::Cipher::CipherError
                raise RubeePass::Error::InvalidPassword.new
            end
        when ID::TWOFISH
            begin
                return StringIO.new(cipher.decrypt(enc))
            rescue ArgumentError
                raise RubeePass::Error::InvalidPassword.new
            end
        end
    end

    def initialize(id, iv, key)
        @id = id
        @iv = iv
        @key = key
    end
end
