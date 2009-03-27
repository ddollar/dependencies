require File.join(File.dirname(__FILE__), 'lib', 'dependencies')

deps = ::Dependencies::Reader.read_file(File.join(Rails.root, 'config', 'dependencies.rb'))

deps.each do |dep|
  dep.options[:require_as] = dep.name unless dep.options.has_key?(:require_as)

  begin
    case dep.options[:require_as]
      when NilClass, FalseClass then next
      else require dep.options[:require_as]
    end
  rescue LoadError
    puts "was unable to require #{dep.name} as '#{require_as}'"
  end
end