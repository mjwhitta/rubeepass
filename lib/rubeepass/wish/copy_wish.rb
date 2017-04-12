require "djinni"

class CopyWish < Djinni::Wish
    def aliases
        return ["copy", "cp"]
    end

    def description
        return "Copy specified field to the clipboard"
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
        path, found, target = path.rpartition("/")
        new_cwd = keepass.find_group_like(path)
        timeout = djinni_env["clipboard_timeout"]

        if (new_cwd.nil? || !new_cwd.has_entry_like?(target))
            puts "Entry not found"
            return
        end

        # Prefer exact match
        entry = new_cwd.entries[target]
        # Fallback to case-insensitive match
        entry ||= new_cwd.entries.select do |k, v|
            k.downcase == target.downcase
        end.values.first

        case field
        when "pass"
            entry.copy_password_to_clipboard
            keepass.send(
                "clear_clipboard_after_#{timeout}_seconds"
            )
        when "url"
            entry.copy_url_to_clipboard
            keepass.send(
                "clear_clipboard_after_#{timeout}_seconds"
            )
        when "user"
            entry.copy_username_to_clipboard
            keepass.send(
                "clear_clipboard_after_#{timeout}_seconds"
            )
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
