require "djinni"

class PwdWish < Djinni::Wish
    def aliases
        return [ "pwd" ]
    end

    def description
        return "Show path of current group"
    end

    def execute(args, djinni_env = {})
        if (args.nil? || args.empty?)
            puts djinni_env["cwd"].path
        else
            usage
        end
    end

    def usage
        puts aliases.join(", ")
        puts "\t#{description}."
    end
end
