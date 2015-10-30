require "cgi"
require "digest"
require "openssl"
require "os"
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
            copy_to_clipboard("")
        end
    end

    def copy_to_clipboard(string)
        string = "" if (string.nil?)
        if (OS::Underlying.windows?)
            puts "Your OS is not currently supported!"
            return
        end

        echo = ScoobyDoo.where_are_you("echo")

        if (OS.mac?)
            string = "" if (string.nil?)
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
                puts "Please install reattach-to-user-namespace!"
                return
            end
        elsif (OS.posix?)
            string = " \x7F" if (string.empty?)
            xclip = ScoobyDoo.where_are_you("xclip")
            xsel = ScoobyDoo.where_are_you("xsel")

            cp = nil
            if (xclip)
                cp = "xclip -i -selection clipboard"
            elsif (xsel)
                cp = "xsel -i --clipboard"
            end

            if (cp)
                system("#{echo} -n #{string.shellescape} | #{cp}")
            else
                puts "Please install either xclip or xsel!"
                return
            end
        else
            puts "Your OS is not currently supported!"
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

    def handle_protected(base64)
        data = nil
        begin
            data = base64.unpack("m*")[0].fix
        rescue ArgumentError => e
            raise Error::InvalidProtectedDataError.new
        end
        raise Error::InvalidProtectedDataError.new if (data.nil?)

        return @protected_decryptor.add_to_stream(data)
    end
    private :handle_protected

    def initialize(kdbx, password, keyfile = nil)
        @kdbx = kdbx
        @keyfile = keyfile
        @password = password
    end

    def join_key_and_keyfile
        passhash = Digest::SHA256.digest(@password)

        filehash = ""
        if (@keyfile)
            contents = File.readlines(@keyfile).join.fix
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
            raise Error::InvalidGzipError.new if (data.nil?)
            id = data.unpack("L*")[0]
            raise Error::InvalidGzipError.new if (block_id != id)

            block_id += 1

            # Read expected hash
            data = file.read(32)
            raise Error::InvalidGzipError.new if (data.nil?)
            expected_hash = data

            # Read size
            data = file.read(4)
            raise Error::InvalidGzipError.new if (data.nil?)
            size = data.unpack("L*")[0]

            # Break is size is 0 and expected hash is all 0's
            if (size == 0)
                expected_hash.each_byte do |byte|
                    if (byte != 0)
                        raise Error::InvalidGzipError.new
                    end
                end
                break
            end

            # Read data and get actual hash
            data = file.read(size)
            actual_hash = Digest::SHA256.digest(data)

            # Check that actual hash is same as expected hash
            if (actual_hash != expected_hash)
                raise Error::InvalidGzipError.new
            end

            # Append data
            gzip += data
        end

        return gzip
    end
    private :parse_gzip

    # Horrible attempt at parsing xml. Someday I might use a library.
    def parse_xml
        curr = Group.new({"Keepass" => self, "Name" => "/"})
        entry_params = Hash.new
        group_params = Hash.new
        ignore = true
        inside_value = false
        status = nil

        @xml.gsub("<", "\n<").each_line do |line|
            line.strip!

            case line
            when "<History>"
                ignore = true
                next
            when "</History>"
                ignore = false
                next
            when "<Root>"
                ignore = false
                next
            when "</Root>"
                break
            when "</Value>"
                status = nil
                inside_value = false
                next
            when ""
                next if (!inside_value)
            end

            line = CGI::unescapeHTML(line)
            line = URI::unescape(line)
            if (!line.valid_encoding?)
                line = line.encode(
                    "UTF-16be",
                    :invalid=>:replace,
                    :replace=>"?"
                ).encode('UTF-8')
            end

            # Handle values with newlines
            if (inside_value && !ignore)
                entry_params[status] += "\n#{line}"
                next
            end

            # Always handle protected data
            case line
            when %r{^<Value Protected="True">.+}
                line.gsub!(%r{^<Value Protected="True">}, "")
                if (ignore)
                    handle_protected(line)
                else
                    entry_params[status] = handle_protected(line)
                end
                next
            else
                next if (ignore)
            end

            case line
            when "<Entry>"
                entry_params = { "Keepass" => self, "Group" => curr }
            when "</Entry>"
                entry = Entry.new(entry_params)
                curr.entries[entry.title] = entry
            when "<Group>"
                group_params = { "Keepass" => self, "Group" => curr }
            when "</Group>"
                curr = curr.group
                break if (curr.nil?)
            when %r{^<Key>.+}
                status = line.gsub(%r{^<Key>}, "")
            when %r{^<Name>.+}
                line.gsub!(%r{^<Name>}, "")
                group_params["Name"] = line

                group = Group.new(group_params)
                curr.groups[group.name] = group
                curr = group
            when %r{^<UUID>.+}
                uuid = line.gsub(%r{^<UUID>}, "")
                if (group_params["UUID"].nil?)
                    group_params["UUID"] = uuid
                else
                    entry_params["UUID"] = uuid
                end
            when %r{^<Value>.*}
                line.gsub!(%r{^<Value>}, "")
                line = "" if (line.nil?)
                entry_params[status] = line
                inside_value = true
            end
        end

        @db = curr
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
        rescue OpenSSL::Cipher::CipherError => e
            raise Error::InvalidPasswordError.new
        end

        if (data.read(32) != @header[@@STREAM_START_BYTES])
            raise Error::InvalidPasswordError.new
        end

        @gzip = parse_gzip(data)
    end
    private :read_gzip

    def read_header(file)
        header = Hash.new
        loop do
            data = file.read(1)
            raise Error::InvalidHeaderError.new if (data.nil?)
            id = data.unpack("C*")[0]

            data = file.read(2)
            raise Error::InvalidHeaderError.new if (data.nil?)
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
            raise Error::InvalidHeaderError.new
        elsif (header[@@INNER_RANDOM_STREAM_ID] != irsi)
            raise Error::NotSalsaError.new
        elsif (header[@@CIPHER_ID].unpack("H*")[0] != aes)
            raise Error::NotAESError.new
        end

        @header = header
    end
    private :read_header

    def read_magic_and_version(file)
        data = file.read(4)
        raise Error::InvalidMagicError.new if (data.nil?)
        sig1 = data.unpack("L*")[0]
        if (sig1 != @@MAGIC_SIG1)
            raise Error::InvalidMagicError.new
        end

        data = file.read(4)
        raise Error::InvalidMagicError.new if (data.nil?)
        sig2 = data.unpack("L*")[0]
        if (sig2 != @@MAGIC_SIG2)
            raise Error::InvalidMagicError.new
        end

        data = file.read(4)
        raise Error::InvalidVersionError.new if (data.nil?)
        ver = data.unpack("L*")[0]
        if ((ver & 0xffff0000) != @@VERSION)
            raise Error::InvalidVersionError.new if (data.nil?)
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
        rescue Interrupt => e
            puts
            return
        end
    end
end

require "rubeepass/entry"
require "rubeepass/error"
require "rubeepass/group"
require "rubeepass/protected_decryptor"
