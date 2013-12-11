require "bundler/gem_tasks"

desc 'Download plupload assets of specified branch(default to master)'
task :download, :branch do |t, args|
  require './lib/tasks/downloader'

  branch = args[:branch]
  Downloader.new(branch).process
end

task default: :test
