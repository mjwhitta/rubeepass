require "hilighter"
require "rexml/document"

class RubeePass::Group
    include Comparable

    attr_accessor :entries
    attr_accessor :group
    attr_accessor :groups
    attr_accessor :keepass
    attr_accessor :name
    attr_accessor :path
    attr_accessor :uuid

    def ==(other)
        return (self.uuid == other.uuid)
    end

    def <=>(other)
        return (self.name.downcase <=> other.name.downcase)
    end

    def details(level = 0, show_passwd = false)
        out = Array.new
        lvl = Array.new(level, "  ").join

        group_details = [ hilight_header(@path) ] if (level == 0)
        group_details = [ hilight_header(@name) ] if (level != 0)

        group_details.each do |line|
            out.push("#{lvl}#{line}")
        end

        @groups.values.each do |group|
            out.push(group.details(level + 1, show_passwd))
        end

        @entries.values.each do |entry|
            out.push(entry.details(level + 1, show_passwd))
        end

        return out.join("\n")
    end

    def entry_titles
        return @entries.keys.sort do |a, b|
            a.downcase <=> b.downcase
        end
    end

    def find_group(path)
        return nil if (@keepass.nil?)

        path = @keepass.absolute_path(path, @path)
        cwd = @keepass.db

        path.split("/").each do |group|
            next if (group.empty?)
            if (cwd.has_group?(group))
                cwd = cwd.groups[group]
            else
                return nil
            end
        end

        return cwd
    end

    def self.from_xml(keepass, parent, xml)
        name = xml.elements["Name"].text if (parent)
        name = "" if (name.nil?)
        name = "/" if (parent.nil?)

        notes = xml.elements["Notes"].text if (parent)
        notes = "" if (notes.nil?)
        notes = "" if (parent.nil?)

        uuid = xml.elements["UUID"].text if (parent)
        uuid = "" if (uuid.nil?)
        uuid = "" if (parent.nil?)

        group = RubeePass::Group.new(
            parent,
            keepass,
            name,
            notes,
            uuid
        )

        if (xml.elements["Entry"])
            xml.elements.each("Entry") do |entry_xml|
                entry = RubeePass::Entry.from_xml(
                    keepass,
                    group,
                    entry_xml
                )
                group.entries[entry.title] = entry
            end
        end

        if (xml.elements["Group"])
            xml.elements.each("Group") do |group_xml|
                child = RubeePass::Group.from_xml(
                    keepass,
                    group,
                    group_xml
                )
                group.groups[child.name] = child
            end
        end

        return group
    end

    def fuzzy_find(search)
        return [[], []] if (@keepass.nil?)

        search = @path if (search.nil? || search.empty?)
        search = @keepass.absolute_path(search, @path)
        path, found, target = search.rpartition("/")

        new_cwd = find_group(path)
        return [[], []] if (new_cwd.nil?)

        if (new_cwd.has_group?(target))
            new_cwd = new_cwd.groups[target]
            target = ""
        end

        group_completions = new_cwd.group_names
        entry_completions = new_cwd.entry_titles

        if (target.empty?)
            return [group_completions, entry_completions]
        end

        group_completions.keep_if do |group|
            group.downcase.start_with?(target.downcase)
        end
        entry_completions.keep_if do |entry|
            entry.downcase.start_with?(target.downcase)
        end

        return [group_completions, entry_completions]
    end

    def group_names
        return @groups.keys.sort do |a, b|
            a.downcase <=> b.downcase
        end
    end

    def has_entry?(title)
        entry_titles.each do |entry|
            return true if (title.downcase == entry.downcase)
        end
        return false
    end

    def has_group?(name)
        group_names.each do |group|
            return true if (name.downcase == group.downcase)
        end
        return false
    end

    def hilight_header(header)
        return header if (!RubeePass.hilight?)
        return header.light_blue
    end
    private :hilight_header

    def initialize(
        group,
        keepass,
        name,
        notes,
        uuid
    )
        @entries = Hash.new
        @group = group
        @groups = Hash.new
        @keepass = keepass
        @name = name
        @notes = notes
        @uuid = uuid

        @path = @name
        @path = "#{@group.path}/#{@name}" if (@group)
        @path.gsub!(%r{^//}, "/")
    end

    def to_s
        return details
    end
end
