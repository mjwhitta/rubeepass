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
        if (self.name.downcase == other.name.downcase)
            return (self.uuid <=> other.uuid)
        end
        return (self.name.downcase <=> other.name.downcase)
    end

    def details(level = 0, show_passwd = false)
        out = Array.new
        lvl = "  " * level

        group_details = [hilight_header(@path)] if (level == 0)
        group_details = [hilight_header(@name)] if (level != 0)

        group_details.each do |line|
            out.push("#{lvl}#{line}")
        end

        @groups.values.each do |group|
            out.push(group.details(level + 1, show_passwd))
        end

        div = "-" * (70 - lvl.length - 2)
        out.push("#{lvl}  #{div}") if (!@entries.empty?)
        @entries.values.each do |entry|
            out.push(entry.details(level + 1, show_passwd))
            out.push("#{lvl}  #{div}")
        end

        return out.join("\n")
    end

    def entry_by_uuid(uuid)
        return @entries[uuid]
    end

    def entry_titles
        return @entries.values.map do |entry|
            entry.title
        end.sort do |a, b|
            a.downcase <=> b.downcase
        end
    end

    def entries_by_title(title, case_insensitive = false)
        return @entries.values.select do |entry|
            (entry.title == title) ||
            (
                case_insensitive &&
                (entry.title.downcase == title.downcase)
            )
        end
    end

    def find_group(path, case_insensitive = false)
        return nil if (@keepass.nil?)

        path = @keepass.absolute_path(path, @path)
        cwd = @keepass.db

        path.split("/").each do |group|
            next if (group.empty?)
            if (cwd.has_group_like?(group))
                cwd = cwd.groups_by_name(group, case_insensitive)[0]
            else
                return nil
            end
        end

        return cwd
    end

    def find_group_like(path)
        return find_group(path, true)
    end

    def self.from_xml(keepass, parent, xml)
        name = "/"
        name = xml.elements["Name"].text || "" if (parent)

        notes = ""
        notes = xml.elements["Notes"].text || "" if (parent)

        uuid = ""
        uuid = xml.elements["UUID"].text || "" if (parent)

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
                group.entries[entry.uuid] = entry
            end
        end

        if (xml.elements["Group"])
            xml.elements.each("Group") do |group_xml|
                child = RubeePass::Group.from_xml(
                    keepass,
                    group,
                    group_xml
                )
                group.groups[child.uuid] = child
            end
        end

        return group
    end

    def fuzzy_find(search)
        return [Array.new, Array.new] if (@keepass.nil?)

        search = @path if (search.nil? || search.empty?)
        search = @keepass.absolute_path(search, @path)
        path, _, target = search.rpartition("/")

        new_cwd = find_group(path)
        return [Array.new, Array.new] if (new_cwd.nil?)

        if (new_cwd.has_group_like?(target))
            new_cwd = new_cwd.groups_by_name(target, true)[0]
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

    def group_by_uuid(uuid)
        return @groups[uuid]
    end

    def group_names
        return @groups.values.map do |group|
            group.name
        end.sort do |a, b|
            a.downcase <=> b.downcase
        end
    end

    def groups_by_name(name, case_insensitive = false)
        return @groups.values.select do |group|
            (group.name == name) ||
            (
                case_insensitive &&
                (group.name.downcase == name.downcase)
            )
        end
    end

    def has_entry?(entry)
        return !entries_by_title(entry).empty?
    end

    def has_entry_like?(entry)
        return !entries_by_title(entry, true).empty?
    end

    def has_group?(group)
        return !groups_by_name(group).empty?
    end

    def has_group_like?(group)
        return !groups_by_name(group, true).empty?
    end

    def hilight_header(header)
        return header if (!RubeePass.hilight?)
        return header.cyan
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
