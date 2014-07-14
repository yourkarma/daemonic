require "bundler/gem_tasks"

begin
  require 'cucumber'
  require 'cucumber/rake/task'

  Cucumber::Rake::Task.new(:features)

rescue LoadError
  task :features do
    puts "Cucumber not installed."
    exit 1
  end
end

task :default => :features
