require "djinni"

class PwdWish < Djinni::Wish
    def aliases
        return ["pwd"]
    end

    def description
        return "Show path of current group"
    end

    def execute(args, djinni_env = Hash.new)
        puts djinni_env["cwd"].path if (args.empty?)
        usage if (!args.empty?)
    end

    def usage
        puts aliases.join(", ")
        puts "    #{description}."
    end
end
