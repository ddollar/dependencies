require File.join(File.dirname(__FILE__), 'lib', 'dependencies')

deps = ::Dependencies::Reader.read_file(File.join(Rails.root, 'config', 'dependencies.rb'))

deps.each do |dep|
  current_environment = ENV['RAILS_ENV'] || 'development'

  options = {
    :only       => [current_environment],
    :except     => [],
    :require_as => dep.name
  }.merge(dep.options)

  # swap their :only and :except to an array if they used a string
  [ :only, :except ].each do |option|
    options[option] = [options[option].to_s] unless options[option].is_a?(Array)
  end

  # don't run if require_as is nil or false
  next if [nil, false].include?(options[:require_as])

  # don't run if the dependency wants an env that is not the current one
  next unless options[:only].include?(current_environment)

  # don't run if the dependency does not want to load in the current env
  next if options[:except].include?(current_environment)

  begin
    require options[:require_as]
  rescue LoadError
    puts "was unable to require #{dep.name} as '#{require_as}'"
  end
end
