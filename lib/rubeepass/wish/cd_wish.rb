require "colorize"
require "djinni"

class CDWish < Djinni::Wish
    def aliases
        return [ "cd" ]
    end

    def description
        return "Change to new group"
    end

    def execute(args, djinni_env = {})
        keepass = djinni_env["keepass"]
        cwd = djinni_env["cwd"]
        prompt_color = djinni_env["prompt_color"]

        args = keepass.absolute_path(args, cwd.path)
        new_cwd = keepass.find_group(args)

        if (new_cwd)
            djinni_env["cwd"] = new_cwd
            if (prompt_color)
                prompt = "rpass:#{new_cwd.name}> ".send(prompt_color)
            else
                prompt = "rpass:#{new_cwd.name}> "
            end
            djinni_env["djinni_prompt"] = prompt
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
