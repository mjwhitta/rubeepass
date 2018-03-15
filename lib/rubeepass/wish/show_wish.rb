require "djinni"

class ShowWish < Djinni::Wish
    def aliases
        return ["cat", "show", "showall"]
    end

    def description
        "Show group/entry contents (showall includes passwords)"
    end

    def execute(args, djinni_env = Hash.new)
        keepass = djinni_env["keepass"]
        cwd = djinni_env["cwd"]

        args = cwd.path if (args.empty?)
        path = keepass.absolute_path(args, cwd.path)
        path, _, target = path.rpartition("/")
        new_cwd = keepass.find_group_like(path)

        if (new_cwd.nil?)
            puts "Group not found"
            return
        end

        if (target.empty?)
            case djinni_env["djinni_input"]
            when "showall"
                puts new_cwd.details(0, true)
            else
                puts new_cwd
            end
        elsif (new_cwd.has_group_like?(target))
            new_cwd.groups_by_name(target, true).each do |group|
                case djinni_env["djinni_input"]
                when "showall"
                    puts group.details(0, true)
                else
                    puts group
                end
            end
        elsif (new_cwd.has_entry_like?(target))
            new_cwd.entries_by_title(target, true).each do |entry|
                case djinni_env["djinni_input"]
                when "showall"
                    puts entry.details(0, true)
                else
                    puts entry
                end
            end
        else
            puts "Group/Entry not found"
        end
    end

    def tab_complete(input, djinni_env = Hash.new)
        cwd = djinni_env["cwd"]
        groups, entries = cwd.fuzzy_find(input)

        completions = Hash.new
        groups.each do |group|
            completions[group] = "Group"
        end
        entries.each do |entry|
            completions[entry] = "Entry"
        end

        append = "/"
        append = "" if (groups.empty?)

        return [completions, input.rpartition("/")[-1], append]
    end

    def usage
        puts "#{aliases.join(", ")} [group|entry]"
        puts "    #{description}."
    end
end
