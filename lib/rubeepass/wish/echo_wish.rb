require "djinni"

class EchoWish < Djinni::Wish
    def aliases
        return ["echo"]
    end

    def description
        return "Echo specified field to stdout"
    end

    def execute(args, djinni_env = Hash.new)
        # "".split(" ", 2) => [] aka [nil, nil]
        # " ".split(" ", 2) => [""] aka ["", nil]
        # "pass".split(" ", 2) => ["pass"] aka ["pass", nil]
        # "pass ".split(" ", 2) => ["pass", ""]

        field, path = args.split(" ", 2)
        if (
            field.nil? ||
            field.empty? ||
            !@fields.include?(field) ||
            path.nil? ||
            path.empty?
        )
            usage
            return
        end

        keepass = djinni_env["keepass"]
        cwd = djinni_env["cwd"]

        path = keepass.absolute_path(path, cwd.path)
        path, _, target = path.rpartition("/")
        new_cwd = keepass.find_group_like(path)

        if (new_cwd.nil? || !new_cwd.has_entry_like?(target))
            puts "Entry not found"
            return
        end

        # Prefer exact match
        entry = new_cwd.entries_by_title(target)[0]

        # Fallback to case-insensitive match
        entry ||= new_cwd.entries_by_title(target, true)[0]

        case field
        when "pass"
            entry.echo_password
        when "url"
            entry.echo_url
        when "user"
            entry.echo_username
        end
    end

    def initialize
        @fields = {
            "pass" => "Password",
            "url" => "URL",
            "user" => "Username"
        }
    end

    def tab_complete(input, djinni_env = Hash.new)
        # "".split(" ", 2) => [] aka [nil, nil]
        # " ".split(" ", 2) => [""] aka ["", nil]
        # "pass".split(" ", 2) => ["pass"] aka ["pass", nil]
        # "pass ".split(" ", 2) => ["pass", ""]

        field, path = input.split(" ", 2)
        return [@fields, "", ""] if (field.nil? || field.empty?)

        if (path.nil?)
            completions = @fields.select do |f, d|
                f.start_with?(field)
            end
            return [completions, field, " "]
        end

        cwd = djinni_env["cwd"]
        groups, entries = cwd.fuzzy_find(path)

        completions = Hash.new
        groups.each do |group|
            completions[group] = "Group"
        end
        entries.each do |entry|
            completions[entry] = "Entry"
        end

        append = "/"
        append = "" if (groups.empty?)

        return [completions, path.rpartition("/")[-1], append]
    end

    def usage
        puts "#{aliases.join(", ")} <field> <entry>"
        puts "    #{description}."
        puts
        puts "FIELDS"
        @fields.each do |field, desc|
            puts "    #{field}"
        end
    end
end
