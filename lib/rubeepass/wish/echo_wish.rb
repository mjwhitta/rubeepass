require "djinni"

class EchoWish < Djinni::Wish
    def aliases
        return [ "echo" ]
    end

    def description
        return "Echo specified field to stdout"
    end

    def execute(args, djinni_env = {})
        if (args.nil? || args.empty?)
            puts usage
            return
        end

        field, args = args.split(" ", 2)
        if (!@fields.include?(field))
            puts usage
            return
        end

        keepass = djinni_env["keepass"]
        cwd = djinni_env["cwd"]
        args = cwd.path if (args.nil? || args.empty?)

        args = keepass.absolute_path(args, cwd.path)
        path, target = args.rsplit("/")
        new_cwd = keepass.find_group(path)

        if (new_cwd)
            if (target.empty?)
                usage
            elsif (new_cwd.has_entry?(target))
                target = new_cwd.entry_titles.select do |entry|
                    target.downcase == entry.downcase
                end.first

                case field
                when "pass"
                    new_cwd.entries[target].echo_password
                when "url"
                    new_cwd.entries[target].echo_url
                when "user"
                    new_cwd.entries[target].echo_username
                end
            else
                puts "Entry \"#{args}\" doesn't exist!"
            end
        else
            puts "Entry \"#{args}\" doesn't exist!"
        end
    end

    def initialize
        @fields = [ "pass", "url", "user" ]
    end

    def tab_complete(input, djinni_env = {})
        if (input.nil? || input.empty?)
            puts
            puts @fields
            return ""
        end

        field, input = input.split(" ", 2)

        if (input.nil? || input.empty?)
            @fields.each do |f|
                break if (f == field)
                if (f.start_with?(field))
                    return "#{f} "
                end
            end
        end

        input = "" if (input.nil?)

        cwd = djinni_env["cwd"]
        input, groups, entries = cwd.fuzzy_find(input)
        if (groups.empty? && entries.empty?)
            return "#{field} #{input.gsub(%r{^#{cwd.path}/?}, "")}"
        end

        path, target = input.rsplit("/")

        if (target.empty?)
            if ((groups.length == 1) && entries.empty?)
                input = "#{path}/#{groups.first}/"
                return "#{field} #{input.gsub(%r{^#{cwd.path}/?}, "")}"
            elsif (groups.empty? && (entries.length == 1))
                input = "#{path}/#{entries.first}"
                return "#{field} #{input.gsub(%r{^#{cwd.path}/?}, "")}"
            end
            puts
            groups.each do |group|
                puts "#{group}/"
            end
            puts entries
            return "#{field} #{input.gsub(%r{^#{cwd.path}/?}, "")}"
        end

        if (!groups.empty?)
            input = "#{path}/#{groups.first}/"
        elsif (!entries.empty?)
            input = "#{path}/#{entries.first}"
        end

        return "#{field} #{input.gsub(%r{^#{cwd.path}/?}, "")}"
    end

    def usage
        puts "#{aliases.join(", ")} <field> <entry>"
        puts "\t#{description}."
        puts
        puts "FIELDS"
        @fields.each do |field|
            puts "\t#{field}"
        end
    end
end
