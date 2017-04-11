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
        path, found, target = path.rpartition("/")
        new_cwd = keepass.find_group(path)

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
        elsif (new_cwd.has_group?(target))
            case djinni_env["djinni_input"]
            when "showall"
                puts new_cwd.groups[target].details(0, true)
            else
                puts new_cwd.groups[target]
            end
        elsif (new_cwd.has_entry?(target))
            new_cwd.entry_titles.select do |entry|
                target.downcase == entry.downcase
            end.each do |entry|
                case djinni_env["djinni_input"]
                when "showall"
                    puts new_cwd.entries[entry].details(0, true)
                else
                    puts new_cwd.entries[entry]
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
