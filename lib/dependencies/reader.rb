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
    @with_options = []
  end

  def dependency(name, *options)
    if @with_options.last
      opts = options.last.is_a?(Hash) ? options.pop : {}
      @with_options.reverse.each { |wo| opts = wo.merge(opts) }
      options.push(opts)
    end
    @dependencies << ::Dependencies::Dependency.new(name, *options)
  end

  def with_options(options={}, &block)
    @with_options.push(options)
    yield
    @with_options.pop
  end

end
