require "string"

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

    def details(level = 0)
        out = Array.new
        lvl = Array.new(level, "  ").join

        group_details = [ "#{@name}".blue ]
        group_details[0] = "#{@path}".blue if (level == 0)

        group_details.each do |line|
            out.push("#{lvl}#{line}")
        end

        @groups.values.each do |group|
            out.push(group.details(level + 1))
        end

        @entries.values.each do |entry|
            out.push(entry.details(level + 1))
        end

        return out.join("\n")
    end

    def entry_titles
        return @entries.keys.sort
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

    def fuzzy_find(input)
        return [ [], [], [] ] if (@keepass.nil?)

        input = @path if (input.nil? || input.empty?)
        input = @keepass.absolute_path(input, @path)
        path, target = input.rsplit("/")

        new_cwd = find_group(path)
        return [ input, [], [] ] if (new_cwd.nil?)

        if (new_cwd.has_group?(target))
            new_cwd = new_cwd.groups[target]
            target = ""
            input += "/"
        end

        group_completions = new_cwd.group_names
        entry_completions = new_cwd.entry_titles

        if (target.empty?)
            return [ input, group_completions, entry_completions ]
        end

        group_completions.delete_if do |group|
            !group.downcase.start_with?(target.downcase)
        end
        entry_completions.delete_if do |entry|
            !entry.downcase.start_with?(target.downcase)
        end

        return [ input, group_completions, entry_completions ]
    end

    def group_names
        return @groups.keys.sort
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

    def initialize(params)
        @entries = Hash.new
        @group = params.fetch("Group", nil)
        @groups = Hash.new
        @keepass = params.fetch("Keepass", nil)
        @name = params.fetch("Name", "")
        @uuid = params.fetch("UUID", "")

        @path = @name
        @path = "#{@group.path}/#{@name}" if (@group)
        @path.gsub!(%r{^//}, "/")
    end

    def to_s
        return details
    end
end
