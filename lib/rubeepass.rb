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
    @@END_OF_HEADER = 0
    @@COMMENT = 1
    @@CIPHER_ID = 2
    @@COMPRESSION = 3
    @@MASTER_SEED = 4
    @@TRANSFORM_SEED = 5
    @@TRANSFORM_ROUNDS = 6
    @@ENCRYPTION_IV = 7
    @@PROTECTED_STREAM_KEY = 8
    @@STREAM_START_BYTES = 9
    @@INNER_RANDOM_STREAM_ID = 10

    @@MAGIC_SIG1 = 0x9aa2d903
    @@MAGIC_SIG2 = 0xb54bfb67
    @@VERSION = 0x00030000

    attr_reader :db
    attr_reader :gzip
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

    def self.colorize?
        @@colorize ||= false
        return @@colorize
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

    def derive_aes_key
        cipher = OpenSSL::Cipher::AES.new(256, :ECB)
        cipher.encrypt
        cipher.key = @header[@@TRANSFORM_SEED]
        cipher.padding = 0

        @header[@@TRANSFORM_ROUNDS].times do
            @key = cipher.update(@key) + cipher.final
        end

        transform_key = Digest::SHA256::digest(@key)
        combined_key = @header[@@MASTER_SEED] + transform_key

        @aes_key = Digest::SHA256::digest(combined_key)
        @aes_iv = @header[@@ENCRYPTION_IV]
    end
    private :derive_aes_key

    def export(export_file, format)
        start_opening

        File.open(export_file, "w") do |f|
            case format
            when "gzip"
                f.write(@gzip)
            when "xml"
                f.write(@xml)
            end
        end
    end

    def extract_xml
        @xml = Zlib::GzipReader.new(StringIO.new(@gzip)).read
    end
    private :extract_xml

    def find_group(path)
        return @db.find_group(path)
    end

    def fuzzy_find(input)
        return @db.fuzzy_find(input)
    end

    def initialize(kdbx, password, keyfile = nil, colorize = false)
        @@colorize = colorize
        @kdbx = Pathname.new(kdbx).expand_path
        @keyfile = nil
        @keyfile = Pathname.new(keyfile).expand_path if (keyfile)
        @password = password

        if (@kdbx.nil?)
            # TODO
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
        passhash = Digest::SHA256.digest(@password)

        filehash = ""
        if (@keyfile)
            contents = File.readlines(@keyfile).join
            if (contents.length != contents.bytesize)
                contents = contents.unpack("H*").pack("H*")
            end
            if (contents[0..4] == "<?xml")
                # XML Key file
                # My ugly attempt to parse a small XML Key file with a
                # poor attempt at schema validation
                keyfile_line = false
                key_line = false
                contents.each_line do |line|
                    line.strip!
                    case line
                    when "<KeyFile>"
                        keyfile_line = true
                    when "<Key>"
                        key_line = true
                    when %r{<Data>.*</Data>}
                        data = line.gsub(%r{^<Data>|</Data>$}, "")
                        data = data.unpack("m*")[0]
                        break if (!keyfile_line || !key_line)
                        break if (data.length != 32)
                        filehash = data
                    end
                end
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

        @key = Digest::SHA256.digest(passhash + filehash)
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
                @header[@@PROTECTED_STREAM_KEY]
            ),
            ["E830094B97205D2A"].pack("H*")
        )

        parse_xml

        return self
    end

    def parse_gzip(file)
        gzip = ""
        block_id = 0

        loop do
            # Read block ID
            data = file.read(4)
            raise Error::InvalidGzip.new if (data.nil?)
            id = data.unpack("L*")[0]
            raise Error::InvalidGzip.new if (block_id != id)

            block_id += 1

            # Read expected hash
            data = file.read(32)
            raise Error::InvalidGzip.new if (data.nil?)
            expected_hash = data

            # Read size
            data = file.read(4)
            raise Error::InvalidGzip.new if (data.nil?)
            size = data.unpack("L*")[0]

            # Break is size is 0 and expected hash is all 0's
            if (size == 0)
                expected_hash.each_byte do |byte|
                    raise Error::InvalidGzip.new if (byte != 0)
                end
                break
            end

            # Read data and get actual hash
            data = file.read(size)
            actual_hash = Digest::SHA256.digest(data)

            # Check that actual hash is same as expected hash
            if (actual_hash != expected_hash)
                raise Error::InvalidGzip.new
            end

            # Append data
            gzip += data
        end

        return gzip
    end
    private :parse_gzip

    def parse_xml
        doc = REXML::Document.new(@xml)
        if (doc.elements["KeePassFile/Root"].nil?)
            raise Error::InvalidXML.new
        end

        root = doc.elements["KeePassFile/Root"]
        @db = Group.from_xml(self, nil, root)
    end
    private :parse_xml

    def read_gzip(file)
        cipher = OpenSSL::Cipher::AES.new(256, :CBC)
        cipher.decrypt
        cipher.key = @aes_key
        cipher.iv = @aes_iv

        encrypted = file.read

        begin
            data = StringIO.new(
                cipher.update(encrypted) + cipher.final
            )
        rescue OpenSSL::Cipher::CipherError
            raise Error::InvalidPassword.new
        end

        if (data.read(32) != @header[@@STREAM_START_BYTES])
            raise Error::InvalidPassword.new
        end

        @gzip = parse_gzip(data)
    end
    private :read_gzip

    def read_header(file)
        header = Hash.new
        loop do
            data = file.read(1)
            raise Error::InvalidHeader.new if (data.nil?)
            id = data.unpack("C*")[0]

            data = file.read(2)
            raise Error::InvalidHeader.new if (data.nil?)
            size = data.unpack("S*")[0]

            data = file.read(size)

            case id
            when @@END_OF_HEADER
                break
            when @@TRANSFORM_ROUNDS
                header[id] = data.unpack("Q*")[0]
            else
                header[id] = data
            end
        end

        irsi = "\x02\x00\x00\x00"
        aes = "31c1f2e6bf714350be5805216afc5aff"
        if (
            (header[@@MASTER_SEED].length != 32) ||
            (header[@@TRANSFORM_SEED].length != 32)
        )
            raise Error::InvalidHeader.new
        elsif (header[@@INNER_RANDOM_STREAM_ID] != irsi)
            raise Error::NotSalsa.new
        elsif (header[@@CIPHER_ID].unpack("H*")[0] != aes)
            raise Error::NotAES.new
        end

        @header = header
    end
    private :read_header

    def read_magic_and_version(file)
        data = file.read(4)
        raise Error::InvalidMagic.new if (data.nil?)
        sig1 = data.unpack("L*")[0]
        raise Error::InvalidMagic.new if (sig1 != @@MAGIC_SIG1)

        data = file.read(4)
        raise Error::InvalidMagic.new if (data.nil?)
        sig2 = data.unpack("L*")[0]
        raise Error::InvalidMagic.new if (sig2 != @@MAGIC_SIG2)

        data = file.read(4)
        raise Error::InvalidVersion.new if (data.nil?)
        ver = data.unpack("L*")[0]
        if ((ver & 0xffff0000) != @@VERSION)
            raise Error::InvalidVersion.new if (data.nil?)
        end
    end
    private :read_magic_and_version

    def start_opening
        @aes_iv = nil
        @aes_key = nil
        @db = nil
        @gzip = nil
        @header = nil
        @key = nil
        @xml = nil

        file = File.open(@kdbx)

        read_magic_and_version(file)
        read_header(file)
        join_key_and_keyfile
        derive_aes_key
        read_gzip(file)

        file.close

        extract_xml
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

require "rubeepass/entry"
require "rubeepass/error"
require "rubeepass/group"
require "rubeepass/protected_decryptor"
