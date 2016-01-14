require "rexml/document"
require "string"

class RubeePass::Entry
    include Comparable

    attr_accessor :group
    attr_accessor :keepass
    attr_accessor :notes
    attr_accessor :path
    attr_accessor :title
    attr_accessor :url
    attr_accessor :username
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
        ret.push("#{lvl}Title    : #{@title}".green)
        # ret.push("#{lvl}UUID     : #{@uuid}")
        ret.push("#{lvl}Username : #{@username}")
        ret.push("#{lvl}Password : #{password}".red) if (show_passwd)
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
            case elem.elements["Key"].text
            when "Notes"
                notes = elem.elements["Value"].text
                notes = "" if (notes.nil?)
            when "Password"
                value = elem.elements["Value"]
                if (value.attributes["Protected"] == "True")
                    password = handle_protected(keepass, value.text)
                else
                    password = value.text
                    password = "" if (password.nil?)
                end
            when "Title"
                title = elem.elements["Value"].text
                title = "" if (title.nil?)
            when "URL"
                url = elem.elements["Value"].text
                url = "" if (url.nil?)
            when "UserName"
                username = elem.elements["Value"].text
                username = "" if (username.nil?)
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
        begin
            data = base64.unpack("m*")[0].fix
        rescue ArgumentError => e
            raise Error::InvalidProtectedDataError.new
        end
        raise Error::InvalidProtectedDataError.new if (data.nil?)

        return keepass.protected_decryptor.add_to_stream(data)
    end

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

    def password
        return nil if (@keepass.nil?)
        begin
            return @keepass.protected_decryptor.get_password(
                @password
            )
        rescue
            return @password
        end
    end

    def to_s
        return details
    end
end
