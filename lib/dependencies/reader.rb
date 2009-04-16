class Dependencies::Reader

  attr_reader :dependencies

  def self.read(definitions)
    reader = new
    reader.instance_eval(definitions)
    reader.dependencies
  end

  def self.read_file(filename)
    self.read(File.read(filename))
  end

  def initialize
    @dependencies = []
  end

  def dependency(name, *options)
    @dependencies << ::Dependencies::Dependency.new(name, *options)
  end

end
