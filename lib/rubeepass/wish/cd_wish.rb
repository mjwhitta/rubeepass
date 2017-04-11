require "djinni"
require "hilighter"

class CDWish < Djinni::Wish
    def aliases
        return ["cd"]
    end

    def description
        return "Change to new group"
    end

    def execute(args, djinni_env = Hash.new)
        keepass = djinni_env["keepass"]
        cwd = djinni_env["cwd"]
        prompt_color = djinni_env["prompt_color"]

        path = keepass.absolute_path(args, cwd.path)
        new_cwd = keepass.find_group(path)

        if (new_cwd.nil?)
            puts "Group not found"
            return
        end

        djinni_env["cwd"] = new_cwd
        if (prompt_color)
            prompt = "rpass:#{new_cwd.name}> ".send(prompt_color)
        else
            prompt = "rpass:#{new_cwd.name}> "
        end
        djinni_env["djinni_prompt"] = prompt
    end

    def tab_complete(input, djinni_env = Hash.new)
        cwd = djinni_env["cwd"]
        groups, entries = cwd.fuzzy_find(input)

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
