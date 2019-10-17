Gem::Specification.new do |s|
    s.name = "rubeepass"
    s.version = "3.4.6"
    s.date = Time.new.strftime("%Y-%m-%d")
    s.summary = "Ruby KeePass 2.x read-only client"
    s.description =
        "Ruby KeePass 2.x client. Currently it is read-only."
    s.authors = ["Miles Whittaker"]
    s.email = "mj@whitta.dev"
    s.executables = Dir.chdir("bin") do
        Dir["*"]
    end
    s.files = Dir["lib/**/*.rb"]
    s.homepage = "https://gitlab.com/mjwhitta/rubeepass"
    s.license = "GPL-3.0"
    s.add_development_dependency("minitest", "~> 5.12", ">= 5.12.2")
    s.add_development_dependency("rake", "~> 13.0", ">= 13.0.0")
    s.add_runtime_dependency("djinni", "~> 2.2", ">= 2.2.5")
    s.add_runtime_dependency("hilighter", "~> 1.3", ">= 1.3.0")
    s.add_runtime_dependency("json_config", "~> 1.1", ">= 1.1.1")
    s.add_runtime_dependency("os", "~> 1.0", ">= 1.0.1")
    s.add_runtime_dependency("salsa20", "~> 0.1", ">= 0.1.3")
    s.add_runtime_dependency("scoobydoo", "~> 1.0", ">= 1.0.1")
    s.add_runtime_dependency("twofish", "~> 1.0", ">= 1.0.8")
end
