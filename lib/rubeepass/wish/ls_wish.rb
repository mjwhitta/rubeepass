require "djinni"

class LSWish < Djinni::Wish
    def aliases
        return ["ls", "dir"]
    end

    def description
        return "List groups and entries in current group"
    end

    def execute(args, djinni_env = Hash.new)
        keepass = djinni_env["keepass"]
        cwd = djinni_env["cwd"]

        args = cwd.path if (args.empty?)
        path = keepass.absolute_path(args, cwd.path)
        new_cwd = keepass.find_group_like(path)

        if (new_cwd.nil?)
            puts "Group not found"
            return
        end

        new_cwd.group_names.each do |group|
            puts "#{group}/"
        end
        new_cwd.entry_titles.each do |entry|
            puts "#{entry}"
        end
    end

    def tab_complete(input, djinni_env = Hash.new)
        cwd = djinni_env["cwd"]
        groups, _ = cwd.fuzzy_find(input)

        completions = Hash.new
        groups.each do |group|
            completions[group] = "Group"
        end

        return [completions, input.rpartition("/")[-1], "/"]
    end

    def usage
        puts "#{aliases.join(", ")} [group]"
        puts "    #{description}."
    end
end
