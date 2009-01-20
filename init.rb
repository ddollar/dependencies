require File.join(File.dirname(__FILE__), 'lib', 'dependencies')

deps = ::Dependencies::Reader.read_file(File.join(Rails.root, 'config', 'dependencies.rb'))

deps.each do |dep|
  require_as = dep.options[:require_as] || dep.name
  require require_as
end