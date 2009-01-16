module Dependencies; end

Dir[File.join(File.dirname(__FILE__), 'depender', '*.rb')].each do |file|
  require file
end