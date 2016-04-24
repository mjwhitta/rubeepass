require "hilighter"
require "rexml/document"

class RubeePass::Entry
    include Comparable

    attr_accessor :group
    attr_accessor :keepass
    attr_accessor :path
    attr_accessor :uuid

    def ==(other)
        return (self.uuid == other.uuid)
    end

    def <=>(other)
        return (self.title.downcase <=> other.title.downcase)
    end

    def details(level = 0, show_passwd = false)
        lvl = Array.new(level, "  ").join

        ret = Array.new
        ret.push(hilight_title("#{lvl}Title    : #{@title}"))
        # ret.push("#{lvl}UUID     : #{@uuid}")
        ret.push("#{lvl}Username : #{@username}")
        if (show_passwd)
            ret.push(
                hilight_password("#{lvl}Password : #{password}")
            )
        end
        ret.push("#{lvl}Url      : #{@url}")

        first = true
        @notes.each_line do |line|
            if (first)
                ret.push("#{lvl}Notes    : #{line.strip}")
                first = false
            else
                ret.push("#{lvl}           #{line.strip}")
            end
        end

        return ret.join("\n")
    end

    def self.from_xml(keepass, parent, xml)
        notes = ""
        password = ""
        title = ""
        url = ""
        username = ""

        uuid = xml.elements["UUID"].text
        uuid = "" if (uuid.nil?)

        xml.elements.each("String") do |elem|
            value = elem.elements["Value"]
            case elem.elements["Key"].text
            when "Notes"
                if (value.attributes["Protected"] == "True")
                    notes = handle_protected(keepass, value.text)
                else
                    notes = value.text
                    notes = "" if (notes.nil?)
                end
            when "Password"
                if (value.attributes["Protected"] == "True")
                    password = handle_protected(keepass, value.text)
                else
                    password = value.text
                    password = "" if (password.nil?)
                end
            when "Title"
                if (value.attributes["Protected"] == "True")
                    title = handle_protected(keepass, value.text)
                else
                    title = value.text
                    title = "" if (title.nil?)
                end
            when "URL"
                if (value.attributes["Protected"] == "True")
                    url = handle_protected(keepass, value.text)
                else
                    url = value.text
                    url = "" if (url.nil?)
                end
            when "UserName"
                if (value.attributes["Protected"] == "True")
                    username = handle_protected(keepass, value.text)
                else
                    username = value.text
                    username = "" if (username.nil?)
                end
            end
        end

        # Handle protected data from history
        xml.elements.each("History/Entry/String/Value") do |value|
            if (value.attributes["Protected"] == "True")
                handle_protected(keepass, value.text)
            end
        end

        return RubeePass::Entry.new(
            parent,
            keepass,
            notes,
            password,
            title,
            url,
            username,
            uuid
        )
    end

    def self.handle_protected(keepass, base64)
        data = nil
        return nil if (base64.nil?)
        begin
            data = base64.unpack("m*")[0]
            if (data.length != data.bytesize)
                data = data.unpack("H*").pack("H*")
            end
        rescue ArgumentError
            raise Error::InvalidProtectedData.new
        end
        raise Error::InvalidProtectedData.new if (data.nil?)

        return keepass.protected_decryptor.add_to_stream(data)
    end

    def hilight_password(passwd)
        return passwd if (!RubeePass.hilight?)
        return passwd.light_red
    end
    private :hilight_password

    def hilight_title(title)
        return title if (!RubeePass.hilight?)
        return title.light_green
    end
    private :hilight_title

    def initialize(
        group,
        keepass,
        notes,
        password,
        title,
        url,
        username,
        uuid
    )
        @group = group
        @keepass = keepass
        @notes = notes
        @password = password
        @title = title
        @url = url
        @username = username
        @uuid = uuid

        @path = @title
        @path = "#{@group.path}/#{@title}" if (@group)
        @path.gsub!(%r{^//}, "/")
    end

    def method_missing(method_name, *args)
        super if (@keepass.nil?)

        if (method_name.to_s.match(/^copy_.+_to_clipboard$/))
            method_name = method_name.to_s.gsub(
                /^copy_(.+)_to_clipboard$/,
                "\\1"
            )
            case method_name
            when "password"
                @keepass.copy_to_clipboard(password)
            when "url"
                @keepass.copy_to_clipboard(@url)
            when "username"
                @keepass.copy_to_clipboard(@username)
            else
                super
            end
        elsif (method_name.match(/^echo_.+$/))
            case method_name.to_s.gsub(/^echo_/, "")
            when "password"
                puts password
            when "url"
                puts @url
            when "username"
                puts @username
            else
                super
            end
        else
            super
        end
    end

    def notes
        return nil if (@keepass.nil?)
        return "" if (@notes.nil?)
        begin
            return @keepass.protected_decryptor.get_password(@notes)
        rescue
            return @notes
        end
    end

    def password
        return nil if (@keepass.nil?)
        return "" if (@password.nil?)
        begin
            return @keepass.protected_decryptor.get_password(
                @password
            )
        rescue
            return @password
        end
    end

    def title
        return nil if (@keepass.nil?)
        return "" if (@title.nil?)
        begin
            return @keepass.protected_decryptor.get_password(@title)
        rescue
            return @title
        end
    end

    def url
        return nil if (@keepass.nil?)
        return "" if (@url.nil?)
        begin
            return @keepass.protected_decryptor.get_password(@url)
        rescue
            return @url
        end
    end

    def username
        return nil if (@keepass.nil?)
        return "" if (@username.nil?)
        begin
            return @keepass.protected_decryptor.get_password(
                @username
            )
        rescue
            return @username
        end
    end

    def to_s
        return details
    end
end
