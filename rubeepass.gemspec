Gem::Specification.new do |s|
    s.name = "rubeepass"
    s.version = "3.1.0"
    s.date = Time.new.strftime("%Y-%m-%d")
    s.summary = "Ruby KeePass 2.x read-only client"
    s.description =
        "Ruby KeePass 2.x client. Currently it is read-only."
    s.authors = [ "Miles Whittaker" ]
    s.email = "mjwhitta@gmail.com"
    s.executables = Dir.chdir("bin") do
        Dir["*"]
    end
    s.files = Dir["lib/**/*.rb"]
    s.homepage = "https://gitlab.com/mjwhitta/rubeepass"
    s.license = "GPL-3.0"
    s.add_development_dependency("minitest", "~> 5.11", ">= 5.11.3")
    s.add_development_dependency("rake", "~> 12.3", ">= 12.3.1")
    s.add_runtime_dependency("djinni", "~> 2.2", ">= 2.2.4")
    s.add_runtime_dependency("hilighter", "~> 1.1", ">= 1.2.3")
    s.add_runtime_dependency("json_config", "~> 0.1", ">= 0.1.4")
    s.add_runtime_dependency("os", "~> 1.0", ">= 1.0.0")
    s.add_runtime_dependency("salsa20", "~> 0.1", ">= 0.1.2")
    s.add_runtime_dependency("scoobydoo", "~> 0.1", ">= 0.1.6")
end
