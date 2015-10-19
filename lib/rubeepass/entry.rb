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

    def initialize(params)
        @group = params.fetch("Group", nil)
        @keepass = params.fetch("Keepass", nil)
        @notes = params.fetch("Notes", "")
        @password = params.fetch("Password", "")
        @title = params.fetch("Title", "")
        @url = params.fetch("URL", "")
        @username = params.fetch("UserName", "")
        @uuid = params.fetch("UUID", "")

        @path = @title
        @path = "#{@group.path}/#{@title}" if (@group)
        @path.gsub!(%r{^//}, "/")
    end

    def method_missing(method_name, *args)
        super if (@keepass.nil?)

        case method_name.to_s.gsub(/^copy_(.+)_to_clipboard$/, "\\1")
        when "password"
            @keepass.copy_to_clipboard(password)
        when "url"
            @keepass.copy_to_clipboard(@url)
        when "username"
            @keepass.copy_to_clipboard(@username)
        else
            super
        end
    end

    def password
        return nil if (@keepass.nil?)
        return @keepass.protected_decryptor.get_password(@password)
    end

    def to_s
        return details
    end
end
