require File.join(File.dirname(__FILE__), 'lib', 'dependencies')

deps = ::Dependencies::Reader.read_file(File.join(Rails.root, 'config', 'dependencies.rb'))

deps.each do |dep|
  current_environment = ENV['RAILS_ENV'] || 'development'

  options = {
    :env        => [current_environment],
    :require_as => dep.name
  }.merge(dep.options)

  # swap their :env to an array if they used a string
  options[:env] = [options[:env]] unless options[:env].is_a?(Array)

  # don't run if require_as is nil or false
  next if [nil, false].include?(options[:require_as])

  # don't run if the gem wants an env that is not the current one
  next unless options[:env].include?(current_environment)

  begin
    require options[:require_as]
  rescue LoadError
    puts "was unable to require #{dep.name} as '#{require_as}'"
  end
end
