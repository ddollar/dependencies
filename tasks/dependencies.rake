require "rubygems"
require "rubygems/source_index"
require "rubygems/dependency_installer"
require "rubygems/uninstaller"
require "fileutils"

Gem.clear_paths
Gem.path.unshift(File.join(RAILS_ROOT, 'gems'))

namespace :dependencies do

  task :setup do
    # avoid requiring environment by working up from vendor/plugins/dependencies/tasks
    rails_root = File.expand_path(File.join(File.dirname(__FILE__), %w(.. .. .. ..)))

    # Dependencies isn't loaded when running from rake.  This is a good place to load it.
    require File.expand_path(File.join(File.dirname(__FILE__), %w(.. lib dependencies))) unless defined?(Dependencies)

    SETTINGS = {
      :dependencies_file => File.join(rails_root, 'config', 'dependencies.rb'),
      :gem_dir           => File.join(rails_root, 'gems')
    }
    FileUtils.mkdir(SETTINGS[:gem_dir]) unless File.exists?(SETTINGS[:gem_dir])
  end

  task :load => :setup do
    SETTINGS[:dependencies] = ::Dependencies::Reader.read_file(SETTINGS[:dependencies_file])
  end

  namespace :transaction do
    task :setup do
      SETTINGS[:gem_original_dir] = SETTINGS[:gem_dir]
      SETTINGS[:gem_dir] = SETTINGS[:gem_dir] + '.install'
    end

    task :begin => :setup do
      FileUtils.rm_rf(SETTINGS[:gem_dir])
      FileUtils.cp_r(SETTINGS[:gem_original_dir], SETTINGS[:gem_dir])
    end

    task :commit => :setup do
      FileUtils.rm_rf(SETTINGS[:gem_original_dir])
      FileUtils.mv(SETTINGS[:gem_dir], SETTINGS[:gem_original_dir])
    end

    task :rollback => :setup do
      FileUtils.rm_rf(SETTINGS[:gem_dir])
    end
  end

  desc 'synchronize the stuff'
  task :sync => [ :setup, :load ] do
    Rake::Task['dependencies:transaction:begin'].invoke

    begin
      repo = Dependencies::Repository.new(SETTINGS[:gem_dir])

      SETTINGS[:dependencies].each do |dep|
        gem = repo.gem(dep.name, dep.versions)
        next unless repo.search(gem).empty?
        repo.install(gem)
      end

      repo.reload_index!

      full_list = SETTINGS[:dependencies].map do |dep|
        gem = repo.gem(dep.name, dep.versions)
        spec = repo.index.search(gem).last
        unless spec
          # Rake::Task['dependencies:transaction:rollback'].invoke # gets run on rescue below.
          raise Exception.new("A required dependency #{gem} was not found")
        end
        deps = spec.recursive_dependencies(gem, repo.index)
        [spec] + deps
      end.flatten.uniq.map do |spec|
        "#{spec.name}-#{spec.version}"
      end
      
      (repo.installed - full_list).each do |g|
        /^(.*)\-(.*)$/ =~ g
        repo.uninstall($1, $2)
      end

      #confirm(gems)

      Rake::Task['dependencies:transaction:commit'].invoke

    rescue Exception => ex
      puts ex.message
      puts ex.backtrace
      Rake::Task['dependencies:transaction:rollback'].invoke
    end
  end
end
