require "djinni"
require "hilighter"

class PwnedPasswordsWish < Djinni::Wish
    def aliases
        return ["check", "pwned"]
    end

    def description
        return [
            "Check passwords against",
            "https://haveibeenpwned.com/passwords"
        ].join(" ")
    end

    def execute(args, djinni_env = Hash.new)
        if (!args.empty?)
            usage
            return
        end

        pwned = djinni_env["keepass"].pwnedpasswords
        pwned.each do |entry|
            puts "#{entry.path.cyan} was pwned: #{entry.password.red}"
        end
        puts "No passwords are known to be pwned" if (pwned.empty?)
    end

    def usage
        puts "#{aliases.join(", ")}"
        puts "    #{description}."
    end
end
