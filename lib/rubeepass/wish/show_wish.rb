require "djinni"

class ShowWish < Djinni::Wish
    def aliases
        return [ "cat", "show", "showall" ]
    end

    def description
        "Show group/entry contents (showall includes passwords)"
    end

    def execute(args, djinni_env = {})
        keepass = djinni_env["keepass"]
        cwd = djinni_env["cwd"]
        args = cwd.path if (args.nil? || args.empty?)

        args = keepass.absolute_path(args, cwd.path)
        path, target = args.rsplit("/")
        new_cwd = keepass.find_group(path)

        if (new_cwd)
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
                puts "Group/entry \"#{args}\" doesn't exist!"
            end
        else
            puts "Group/entry \"#{args}\" doesn't exist!"
        end
    end

    def tab_complete(input, djinni_env = {})
        cwd = djinni_env["cwd"]
        input, groups, entries = cwd.fuzzy_find(input)
        if (groups.empty? && entries.empty?)
            return input.gsub(%r{^#{cwd.path}/?}, "")
        end

        path, target = input.rsplit("/")

        if (target.empty?)
            if ((groups.length == 1) && entries.empty?)
                input = "#{path}/#{groups.first}/"
                return input.gsub(%r{^#{cwd.path}/?}, "")
            elsif (groups.empty? && (entries.length == 1))
                input = "#{path}/#{entries.first}"
                return input.gsub(%r{^#{cwd.path}/?}, "")
            end
            puts
            groups.each do |group|
                puts "#{group}/"
            end
            puts entries
            return input.gsub(%r{^#{cwd.path}/?}, "")
        end

        if (!groups.empty?)
            input = "#{path}/#{groups.first}/"
        elsif (!entries.empty?)
            input = "#{path}/#{entries.first}"
        end

        return input.gsub(%r{^#{cwd.path}/?}, "")
    end

    def usage
        puts "#{aliases.join(", ")} [group|entry]"
        puts "\t#{description}."
    end
end
