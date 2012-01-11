require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.test_files = FileList['spec/**/*_spec.rb']
  t.verbose = true
end

desc "Generate a coverage report from tests with simplecov"
task :coverage do  
  ENV['SCOV'] = '1'
  Rake::Task['test'].invoke
end
