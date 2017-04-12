require "hilighter"
require "rexml/document"

class RubeePass::Entry
    include Comparable

    attr_accessor :group
    attr_accessor :keepass
    attr_accessor :notes
    attr_accessor :password
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

    def additional_attributes
        return attributes.select do |key, value|
            key.match(/^(notes|password|title|url|username)$/i).nil?
        end
    end

    def attachment(name)
        return nil if (@keepass.nil?)
        return nil if (!has_attachment?(name))
        return @keepass.attachment_decoder.get_attachment(
            @attachments[name]
        )
    end

    def attachments
        attachments = Hash.new

        @attachments.each do |key, value|
            attachments[key] = attachment(key)
        end

        return attachments
    end

    def attribute(attr)
        return nil if (@keepass.nil?)
        return "" if (!has_attribute?(attr))

        begin
            return @keepass.protected_decryptor.decrypt(
                @attributes[attr]
            )
        rescue
            return @attributes[attr]
        end
    end

    def attributes
        return nil if (@keepass.nil?)

        attrs = Hash.new
        @attributes.each do |key, value|
            attrs[key] = attribute(key)
        end

        return attrs
    end

    def details(level = 0, show_passwd = false)
        lvl = "  " * level

        r = Array.new
        r.push("#{lvl}#{hilight_attr("Title:")} #{@title}")
        # r.push("#{lvl}#{hilight_attr("UUID:")} #{@uuid}")
        r.push("#{lvl}#{hilight_attr("Username:")} #{@username}")
        if (show_passwd)
            r.push(
                "#{lvl}#{hilight_password("Password:")} #{@password}"
            )
        end
        r.push("#{lvl}#{hilight_attr("URL:")} #{@url}")

        r.push("#{lvl}#{hilight_attr("Notes:")}") if (!@notes.empty?)
        @notes.each_line do |line|
            r.push("#{lvl}  #{line.strip}")
        end

        additional_attributes.each do |k, v|
            r.push("#{lvl}#{hilight_attr("#{k}:")} #{v}")
        end

        if (!@attachments.empty?)
            r.push("#{lvl}#{hilight_attr("Attachments:")}")
        end
        @attachments.keys.each do |name|
            r.push("#{lvl}  #{name}")
        end

        return r.join("\n")
    end

    def self.from_xml(keepass, parent, xml)
        attrs = Hash.new
        attachs = Hash.new

        uuid = xml.elements["UUID"].text || ""

        xml.elements.each("String") do |elem|
            key = elem.elements["Key"].text
            value = elem.elements["Value"]

            attrs[key] = value.text || ""
            if (value.attributes["Protected"] == "True")
                attrs[key] = handle_protected(keepass, value.text)
            end
        end

        # Handle protected data from history
        xml.elements.each("History/Entry/String/Value") do |value|
            if (value.attributes["Protected"] == "True")
                handle_protected(keepass, value.text)
            end
        end

        xml.elements.each("Binary") do |elem|
            key = elem.elements["Key"].text
            value = elem.elements["Value"].attributes["Ref"]
            attachs[key] = value
        end

        return RubeePass::Entry.new(
            parent,
            keepass,
            attrs,
            attachs,
            uuid
        )
    end

    def self.handle_protected(keepass, base64)
        return nil if (base64.nil?)

        data = nil
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

    def has_attachment?(name)
        return !@attachments[name].nil?
    end

    def has_attachment_like?(name)
        return @attachments.any? do |k, v|
            k.downcase == name.downcase
        end
    end

    def has_attribute?(attr)
        return !@attributes[attr].nil?
    end

    def has_attribute_like?(attr)
        return @attributes.any? do |k, v|
            k.downcase == attr.downcase
        end
    end

    def hilight_attr(title)
        return title if (!RubeePass.hilight?)
        return title.light_green
    end
    private :hilight_attr

    def hilight_password(passwd)
        return passwd if (!RubeePass.hilight?)
        return passwd.light_red
    end
    private :hilight_password

    def initialize(group, keepass, attributes, attachments, uuid)
        @group = group
        @keepass = keepass
        @attributes = attributes
        @attachments = attachments

        @notes = attribute("Notes")
        @password = attribute("Password")
        @title = attribute("Title")
        @url = attribute("URL")
        @username = attribute("UserName")

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
                @keepass.copy_to_clipboard(@password)
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
                puts @password
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

    def to_s
        return details
    end
end
