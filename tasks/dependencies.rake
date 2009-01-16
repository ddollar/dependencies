require "rubygems"
require "rubygems/source_index"
require "rubygems/dependency_installer"
require "rubygems/uninstaller"
require "fileutils"

namespace :dependencies do

  task :setup => :environment do
    SETTINGS = {
      :dependencies_file => File.join(Rails.root, 'config', 'dependencies.rb'),
      :gem_dir           => File.join(Rails.root, 'gems')
    }
    #SETTINGS[:gem_gems_dir] = File.join(SETTINGS[:gem_dir], 'gems')
    #SETTINGS[:gem_spec_dir] = File.join(SETTINGS[:gem_dir], 'specifications')
    FileUtils.mkdir_p(SETTINGS[:gem_dir])
  end

  task :load => :setup do
    SETTINGS[:dependencies] = ::Dependencies::Reader.read_file(SETTINGS[:dependencies_file])
    #SETTINGS[:index]        = ::Gem::SourceIndex.new.load_gems_in(SETTINGS[:gem_spec_dir])
  end

  namespace :transaction do
    task :setup do
      SETTINGS[:gem_backup_dir] = SETTINGS[:gem_dir] + '.original'
    end

    task :begin => :setup do
      FileUtils.cp_r(SETTINGS[:gem_dir], SETTINGS[:gem_backup_dir])
    end

    task :commit => :setup do
      FileUtils.rm_rf(SETTINGS[:gem_backup_dir])
    end

    task :rollback => :setup do
      if File.exist?(SETTINGS[:gem_backup_dir])
        FileUtils.rm_rf(SETTINGS[:gem_dir])
        FileUtils.mv(SETTINGS[:gem_backup_dir], SETTINGS[:gem_dir])
      end
      exit 1
    end
  end

  desc 'synchronize the stuff'
  task :sync => [ :setup, :load ] do

    Rake::Task['dependencies:transaction:begin'].invoke

    repo = Dependencies::Repository.new(SETTINGS[:gem_dir])

    SETTINGS[:dependencies].each do |name, versions|
      gem = repo.gem(name, versions)
      next unless repo.search(gem).empty?

      begin
        repo.install(gem)
      rescue StandardError => ex
        puts ex.message
        puts ex.backtrace
        Rake::Task['dependencies:transaction:rollback'].invoke
      end
    end

    repo.reload_index!

    full_list = SETTINGS[:dependencies].each do |name, versions|
      gem = repo.gem(name, versions)
      spec = repo.index.search(gem).last
      pp gem
      pp repo.index.search(gem)
      unless spec
        puts "A required dependency #{gem} was not found"
        Rake::Task['dependencies:transaction:rollback'].invoke
      end
      deps = spec.recursive_dependencies(gem, repo.index)
      [spec] + deps
    end.flatten.uniq

    (repo.installed - full_list).each do |g|
      /^(.*)\-(.*)$/ =~ g
      name, version = $1, $2
      uninstaller = ::Gem::Uninstaller.new(name,
        :version => version,
        :bin_dir => (Dir.pwd / "bin").to_s,
        :install_dir => (Dir.pwd / "gems").to_s,
        :ignore => true,
        :executables => true
      )
      uninstaller.uninstall
    end

    confirm(gems)

    self.class.commit_trans
  end
end
