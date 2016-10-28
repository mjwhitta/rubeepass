Gem::Specification.new do |s|
    s.name = "rubeepass"
    s.version = "1.0.4"
    s.date = Time.new.strftime("%Y-%m-%d")
    s.summary = "Ruby KeePass 2.x implementation"
    s.description =
        "Ruby KeePass 2.x implementation. Currently it is read-only."
    s.authors = [ "Miles Whittaker" ]
    s.email = "mjwhitta@gmail.com"
    s.executables = Dir.chdir("bin") do
        Dir["*"]
    end
    s.files = Dir["lib/**/*.rb"]
    s.homepage = "https://mjwhitta.github.io/rubeepass"
    s.license = "GPL-3.0"
    s.add_development_dependency("minitest", "~> 5.9", ">= 5.9.1")
    s.add_development_dependency("rake", "~> 11.3", ">= 11.3.0")
    s.add_runtime_dependency("djinni", "~> 2.0", ">= 2.0.1")
    s.add_runtime_dependency("hilighter", "~> 0.1", ">= 0.1.7")
    s.add_runtime_dependency("json_config", "~> 0.1", ">= 0.1.2")
    s.add_runtime_dependency("os", "~> 0.9", ">= 0.9.6")
    s.add_runtime_dependency("salsa20", "~> 0.1", ">= 0.1.2")
    s.add_runtime_dependency("scoobydoo", "~> 0.1", ">= 0.1.4")
end
