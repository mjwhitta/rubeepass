require "rake/testtask"

task :default => :gem

desc "Clean up"
task :clean do
    system("rm -f *.gem Gemfile.lock")
    system("chmod -R go-rwx bin lib")
end

desc "Test example project"
task :ex => :install do
    system(
        [
            "bin/rpass -p asdf -k test/key/key.xml",
            "test/kdbx/kdf3_aes_aes.kdbx"
        ].join(" ")
    )
end

desc "Build gem"
task :gem do
    system("chmod -R u=rwX,go=rX bin lib")
    system("gem build *.gemspec")
end

desc "Build and install gem"
task :install => :gem do
    system("gem install *.gem")
end

desc "Push gem to rubygems.org"
task :push => [:clean, :gem] do
    system("gem push *.gem")
end

desc "Run tests"
Rake::TestTask.new do |t|
    t.libs << "test"
end
