Gem::Specification.new do |s|
    s.add_development_dependency("minitest", "~> 5.12", ">= 5.12.2")
    s.add_development_dependency("rake", "~> 13.0", ">= 13.0.0")
    s.add_runtime_dependency("djinni", "~> 2.2", ">= 2.2.5")
    s.add_runtime_dependency("hilighter", "~> 1.5", ">= 1.5.1")
    s.add_runtime_dependency("jsoncfg", "~> 1.1", ">= 1.1.3")
    s.add_runtime_dependency("os", "~> 1.0", ">= 1.0.1")
    s.add_runtime_dependency("salsa20", "~> 0.1", ">= 0.1.3")
    s.add_runtime_dependency("scoobydoo", "~> 1.0", ">= 1.0.1")
    s.add_runtime_dependency("twofish", "~> 1.0", ">= 1.0.8")
    s.authors = ["Miles Whittaker"]
    s.date = Time.new.strftime("%Y-%m-%d")
    s.description = [
        "Ruby KeePass 2.x client. Currently it is read-only."
    ].join(" ")
    s.email = "mj@whitta.dev"
    s.executables = Dir.chdir("bin") do
        Dir["*"]
    end
    s.files = Dir["lib/**/*.rb"]
    s.homepage = "https://gitlab.com/mjwhitta/rubeepass"
    s.license = "GPL-3.0"
    s.metadata = {"source_code_uri" => s.homepage}
    s.name = "rubeepass"
    s.summary = "Ruby KeePass 2.x read-only client"
    s.version = "3.4.8"
end
