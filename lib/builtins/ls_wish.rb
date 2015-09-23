require "djinni"
require "string"

class LSWish < Djinni::Wish
    def aliases
        return [ "ls", "dir" ]
    end

    def description
        return "List groups and entries in current group"
    end

    def execute(args, djinni_env = {})
        keepass = djinni_env["keepass"]
        cwd = djinni_env["cwd"]
        args = cwd.path if (args.nil? || args.empty?)

        args = keepass.absolute_path(args, cwd.path)
        new_cwd = keepass.find_group(args)

        if (new_cwd)
            new_cwd.group_names.each do |group|
                puts "#{group}/"
            end
            new_cwd.entry_titles.each do |entry|
                puts "#{entry}"
            end
        else
            puts "Group \"#{args}\" doesn't exist!"
        end
    end

    def tab_complete(input, djinni_env = {})
        cwd = djinni_env["cwd"]
        input, groups = cwd.fuzzy_find(input)
        return input.gsub(%r{^#{cwd.path}/?}, "") if (groups.empty?)

        path, dest = input.rsplit("/")

        if (dest.empty?)
            if (groups.length == 1)
                input = "#{path}/#{groups.first}/"
                return input.gsub(%r{^#{cwd.path}/?}, "")
            end
            puts
            groups.each do |group|
                puts "#{group}/"
            end
            return input.gsub(%r{^#{cwd.path}/?}, "")
        end

        input = "#{path}/#{groups.first}/"
        return input.gsub(%r{^#{cwd.path}/?}, "")
    end

    def usage
        puts "#{aliases.join(", ")} [group]"
        puts "\t#{description}."
    end
end
