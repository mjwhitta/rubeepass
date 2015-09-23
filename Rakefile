require "rake/testtask"

task :default => :gem

desc "Clean up"
task :clean do
    system("rm -f *.gem Gemfile.lock")
    system("chmod -R go-rwx bin lib")
end

desc "Test example project"
task :ex => :install do
    system("bin/rpass -p asdf -k test/asdf.xml test/asdf.kdbx")
end

desc "Build gem"
task :gem do
    system("chmod -R u=rwX,go=rX bin lib")
    system("gem build rubeepass.gemspec")
end

desc "Build and install gem"
task :install => :gem do
    system("gem install rubeepass*.gem")
end

desc "Run tests"
Rake::TestTask.new do |t|
    t.libs << "test"
end
