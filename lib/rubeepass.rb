require "cgi"
require "digest"
require "openssl"
require "os"
require "pathname"
require "rexml/document"
require "scoobydoo"
require "shellwords"
require "uri"
require "zlib"

class RubeePass
    # Header fields
    module Header
        END_OF_HEADER = 0
        COMMENT = 1
        CIPHER_ID = 2
        COMPRESSION = 3
        MASTER_SEED = 4
        TRANSFORM_SEED = 5
        TRANSFORM_ROUNDS = 6
        ENCRYPTION_IV = 7
        PROTECTED_STREAM_KEY = 8
        STREAM_START_BYTES = 9
        INNER_RANDOM_STREAM_ID = 10
        KDF_PARAMETERS = 11
        PUBLIC_CUSTOM_DATA = 12
    end

    # Inner header fields
    module InnerHeader
        END_OF_HEADER = 0
        RANDOM_STREAM_ID = 1
        RANDOM_STREAM_KEY = 2
        BINARY = 3
    end

    # Magic values
    module Magic
        SIG1 = 0x9aa2d903
        SIG2 = 0xb54bfb67
        VERSION3 = 0x00030000
        VERSION31 = 0x00030001
        VERSION4 = 0x00040000
    end

    # Stream algorithm
    module StreamAlgorithm
        ARC_FOUR_VARIANT = 1
        SALSA20 = 2
        CHACHA20 = 3
    end

    attr_reader :attachment_decoder
    attr_reader :db
    attr_reader :protected_decryptor
    attr_reader :xml

    def absolute_path(to, from = "/")
        return "/" if (to.nil? || to.empty? || (to == "/"))
        from = "/" if (to.start_with?("/"))

        path = Array.new

        from.split("/").each do |group|
            next if (group.empty?)
            case group
            when "."
                # Do nothing
            when ".."
                path.pop
            else
                path.push(group)
            end
        end

        to.split("/").each do |group|
            next if (group.empty?)
            case group
            when "."
                # Do nothing
            when ".."
                path.pop
            else
                path.push(group)
            end
        end

        return "/#{path.join("/")}"
    end

    def clear_clipboard(time = 0)
        @thread.kill if (@thread)
        @thread = Thread.new do
            sleep time
            copy_to_clipboard("", false)
        end
    end

    def self.hilight?
        @@hilight ||= false
        return @@hilight
    end

    def copy_to_clipboard(string, err = true)
        string = "" if (string.nil?)
        if (OS::Underlying.windows?)
            puts "Your OS is not currently supported!" if (err)
            return
        end

        return if (ENV["DISPLAY"].nil? || ENV["DISPLAY"].empty?)

        echo = ScoobyDoo.where_are_you("echo")

        if (OS.mac?)
            pbcopy = ScoobyDoo.where_are_you("pbcopy")
            rn = ScoobyDoo.where_are_you("reattach-to-user-namespace")

            cp = pbcopy
            if (ENV["TMUX"])
                cp = nil
                cp = "#{rn} #{pbcopy}" if (rn)
            end

            if (cp)
                system("#{echo} -n #{string.shellescape} | #{cp}")
            else
                if (err)
                    puts "Please install reattach-to-user-namespace!"
                end
                return
            end
        elsif (OS.posix?)
            xclip = ScoobyDoo.where_are_you("xclip")
            xsel = ScoobyDoo.where_are_you("xsel")

            ["clipboard", "primary", "secondary"].each do |sel|
                cp = nil
                if (xclip)
                    # string = " \x7F" if (string.empty?)
                    cp = "xclip -i -selection #{sel}"
                elsif (xsel)
                    cp = "xsel -i --#{sel}"
                end

                if (cp)
                    system("#{echo} -n #{string.shellescape} | #{cp}")
                else
                    if (err)
                        puts "Please install either xclip or xsel!"
                    end
                    return
                end
            end
        else
            puts "Your OS is not currently supported!" if (err)
            return
        end
    end

    def decompress(compressed)
        if (!@header[Header::COMPRESSION])
            # This feels like a hack
            m = compressed.read.match(
                /\<KeePassFile\>.+\<\/KeePassFile\>/m
            )
            return m[0] if (m.length > 0)
            return nil
        end

        gzip = ""
        block_id = 0

        loop do
            # Read block ID
            data = compressed.read(4)
            raise Error::InvalidGzip.new if (data.nil?)
            id = data.unpack("L*")[0]
            raise Error::InvalidGzip.new if (block_id != id)

            block_id += 1

            # Read expected hash
            data = compressed.read(32)
            raise Error::InvalidGzip.new if (data.nil?)
            expected_hash = data

            # Read size
            data = compressed.read(4)
            raise Error::InvalidGzip.new if (data.nil?)
            size = data.unpack("L*")[0]

            # Break if size is 0 and expected hash is all 0's
            if (size == 0)
                expected_hash.each_byte do |byte|
                    raise Error::InvalidGzip.new if (byte != 0)
                end
                break
            end

            # Read data and get actual hash
            data = compressed.read(size)
            actual_hash = Digest::SHA256.digest(data)

            # Check that actual hash is same as expected hash
            if (actual_hash != expected_hash)
                raise Error::InvalidGzip.new
            end

            # Append data
            gzip += data
        end

        # Unzip gzip data
        return Zlib::GzipReader.new(StringIO.new(gzip)).read
    end
    private :decompress

    def derive_kdf3_key
        case @version
        when Magic::VERSION4
            raise Error::InvalidHeader.new("KDF3 with version 4")
        end

        irsi = "\x02\x00\x00\x00"
        if (
            (@header[Header::MASTER_SEED].length != 32) ||
            (@header[Header::TRANSFORM_SEED].length != 32)
        )
            raise Error::InvalidHeader.new("Invalid seed size")
        elsif (@header[Header::INNER_RANDOM_STREAM_ID] != irsi)
            raise Error::NotSalsa.new
        end

        cipher = OpenSSL::Cipher::AES.new(256, :ECB)
        cipher.encrypt
        cipher.key = @header[Header::TRANSFORM_SEED]
        cipher.padding = 0

        key = @initial_key
        @header[Header::TRANSFORM_ROUNDS].times do
            key = cipher.update(key) + cipher.final
        end

        transform_key = Digest::SHA256::digest(key)
        combined_key = @header[Header::MASTER_SEED] + transform_key

        @cipher = Cipher.new(
            @header[Header::CIPHER_ID],
            @header[Header::ENCRYPTION_IV],
            Digest::SHA256::digest(combined_key)
        )
    end
    private :derive_kdf3_key

    def derive_kdf4_key(file)
        case @version
        when Magic::VERSION3, Magic::VERSION31
            raise Error::InvalidHeader.new("KDF4 with version 3")
        end

        sha = file.read(32)
        hmac = file.read(32)

        if (sha.nil? || (sha.length != 32))
            raise Error::InvalidHeader.new("Invalid SHA size")
        end
        if (hmac.nil? || (hmac.length != 32))
            raise Error::InvalidHeader.new("Invalid HMAC size")
        end

        # TODO check SHA and HMAC (eh, later)

        # TODO implement kdf4 key derivation

        raise Error::NotSupported.new("AES with new KDF")
    end
    private :derive_kdf4_key

    def derive_key(file)
        if (
            @header[Header::TRANSFORM_ROUNDS].nil? ||
            @header[Header::TRANSFORM_SEED].nil?
        )
            derive_kdf4_key(file)
        else
            derive_kdf3_key
        end
    end
    private :derive_key

    def export(export_file, format)
        start_opening

        File.open(export_file, "w") do |f|
            case format
            when "gzip"
                gz = Zlib::GzipWriter.new(f)
                gz.write(@xml)
                gz.close
            when "xml"
                f.write(@xml)
            end
        end
    end

    def find_group(path)
        return @db.find_group(path)
    end

    def find_group_like(path)
        return @db.find_group(path, true)
    end

    def fuzzy_find(input)
        return @db.fuzzy_find(input)
    end

    def initialize(kdbx, password, keyfile = nil, hilight = false)
        @@hilight = hilight
        @kdbx = Pathname.new(kdbx).expand_path
        @keyfile = nil
        @keyfile = Pathname.new(keyfile).expand_path if (keyfile)
        @password = password

        if (@kdbx.nil?)
            raise RubeePass::Error::FileNotFound.new("null")
        elsif (!@kdbx.exist?)
            raise RubeePass::Error::FileNotFound.new(@kdbx)
        elsif (!@kdbx.readable?)
            raise RubeePass::Error::FileNotReadable.new(@kdbx)
        end

        if (@keyfile)
            if (!@keyfile.exist?)
                raise RubeePass::Error::FileNotFound.new(@keyfile)
            elsif (!@keyfile.readable?)
                raise RubeePass::Error::FileNotReadable.new(@keyfile)
            end
        end
    end

    def join_key_and_keyfile
        filehash = ""
        if (@keyfile)
            contents = File.readlines(@keyfile).join
            if (contents.length != contents.bytesize)
                contents = contents.unpack("H*").pack("H*")
            end
            if (contents[0..4] == "<?xml")
                # Parse XML for data
                doc = REXML::Document.new(contents)
                data = doc.elements["KeyFile/Key/Data"]
                raise Error::InvalidXML.new if (data.nil?)
                filehash = data.text.unpack("m*")[0]
            elsif (contents.length == 32)
                # Not XML but a 32 byte Key file
                filehash = contents
            elsif (contents.length == 64)
                # Not XML but a 64 byte Key file
                if (contents.match(/^[0-9A-Fa-f]+$/))
                    filehash = [contents].pack("H*")
                end
            else
                # Not a Key file
                filehash = Digest::SHA256.digest(contents)
            end
        end

        if @password.nil?
            @initial_key = Digest::SHA256.digest(filehash)
        else
            passhash = Digest::SHA256.digest(@password)
            @initial_key = Digest::SHA256.digest(passhash + filehash)
        end
    end
    private :join_key_and_keyfile

    def method_missing(method_name, *args)
        if (method_name.to_s.match(/^clear_clipboard_after_/))
            mn = method_name.to_s.gsub!(/^clear_clipboard_after_/, "")
            case mn
            when /^[0-9]+_sec(ond)?s$/
                time = mn.gsub(/_sec(ond)?s$/, "").to_i
                clear_clipboard(time)
            when /^[0-9]+_min(ute)?s$/
                time = mn.gsub(/_min(ute)?s$/, "").to_i
                clear_clipboard(time * 60)
            else
                super
            end
        else
            super
        end
    end

    def open
        start_opening

        @protected_decryptor = ProtectedDecryptor.new(
            Digest::SHA256.digest(
                @header[Header::PROTECTED_STREAM_KEY]
            ),
            ["E830094B97205D2A"].pack("H*")
        )

        parse_xml

        return self
    end

    def parse_xml
        doc = REXML::Document.new(@xml)
        if (doc.elements["KeePassFile/Root"].nil?)
            raise Error::InvalidXML.new
        end

        @attachment_decoder = AttachmentDecoder.new(
            doc.elements["KeePassFile/Meta/Binaries"]
        )

        root = doc.elements["KeePassFile/Root"]
        @db = Group.from_xml(self, nil, root)
    end
    private :parse_xml

    def pwnedpasswords(group = @db)
        return [] if (group.nil?)

        pwned = Array.new
        group.groups.each do |name, subgroup|
            pwned.concat(pwnedpasswords(subgroup))
        end
        group.entries.each do |name, entry|
            pwned.push(entry) if (entry.is_pwned?)
        end

        return pwned
    end

    def read_header(file)
        header = Hash.new
        loop do
            data = file.read(1)
            break if (data.nil?)
            id = data.unpack("C*")[0]

            case @version
            when Magic::VERSION3, Magic::VERSION31
                data = file.read(2)
            when Magic::VERSION4
                data = file.read(4)
            else
                raise Error::InvalidHeader.new
            end
            raise Error::InvalidHeader.new if (data.nil?)
            size = data.unpack("S*")[0]

            data = file.read(size)
            if (data.nil? && (size > 0))
                raise Error::InvalidHeader.new
            end

            case id
            when Header::CIPHER_ID
                header[id] = data.unpack("H*")[0]
            when Header::COMPRESSION
                header[id] = (data.unpack("L*")[0] > 0)
            when Header::END_OF_HEADER
                break
            when Header::KDF_PARAMETERS
                case @version
                when Magic::VERSION3, Magic::VERSION31
                    raise Error::InvalidHeader.new
                end
                # raise Error::NotSupported.new("Custom KDF params")
            when Header::PUBLIC_CUSTOM_DATA
                case @version
                when Magic::VERSION3, Magic::VERSION31
                    raise Error::InvalidHeader.new
                end
                raise Error::NotSupported.new("Public custom data")
            when Header::TRANSFORM_ROUNDS
                header[id] = data.unpack("Q*")[0]
            else
                case @version
                when Magic::VERSION4
                    case id
                    when Header::INNER_RANDOM_STREAM_ID,
                         Header::PROTECTED_STREAM_KEY,
                         Header::STREAM_START_BYTES,
                         Header::TRANSFORM_ROUNDS,
                         Header::TRANSFORM_SEED
                        raise Error::InvalidHeader.new(
                            "Legacy header ID"
                        )
                    end
                end
                header[id] = data
            end
        end

        @header = header
    end
    private :read_header

    def read_magic_and_version(file)
        data = file.read(4)
        raise Error::InvalidMagic.new if (data.nil?)
        @sig1 = data.unpack("L*")[0]
        # raise Error::InvalidMagic.new if (@sig1 != Magic::SIG1)

        data = file.read(4)
        raise Error::InvalidMagic.new if (data.nil?)
        @sig2 = data.unpack("L*")[0]
        # raise Error::InvalidMagic.new if (@sig2 != Magic::SIG2)

        data = file.read(4)
        raise Error::InvalidVersion.new if (data.nil?)
        @version = data.unpack("L*")[0]
        case @version
        when Magic::VERSION3, Magic::VERSION31, Magic::VERSION4
        else
            raise Error::InvalidVersion.new
        end
    end
    private :read_magic_and_version

    def start_opening
        @cipher = nil
        @db = nil
        @header = nil
        @initial_key = nil
        @sig1 = nil
        @sig2 = nil
        @version = nil
        @xml = nil

        file = File.open(@kdbx)

        # Read metadata and derive key
        read_magic_and_version(file)
        read_header(file)
        join_key_and_keyfile
        derive_key(file)

        # Decrypt file
        encrypted = file.read
        decrypted = @cipher.decrypt(encrypted)
        if (decrypted.read(32) != @header[Header::STREAM_START_BYTES])
            raise Error::InvalidPassword.new
        end

        # Decompress (if necessary)
        @xml = decompress(decrypted)

        file.close
    end
    private :start_opening

    def to_s
        return @db.to_s
    end

    def wait_to_exit
        return if (@thread.nil?)
        begin
            @thread.join
        rescue Interrupt
            puts
        end
    end
end

require "rubeepass/attachment_decoder"
require "rubeepass/cipher"
require "rubeepass/entry"
require "rubeepass/error"
require "rubeepass/group"
require "rubeepass/protected_decryptor"
