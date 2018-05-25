require 'erb'
require 'fileutils'
require 'json'

class JPath
  def initialize(array)
    @path = array
  end # JPath#initialize

  def to_filepath(outputdir)
    "#{outputdir}/#{@path.join('/')}/index.html"
  end # JPath#to_filepath

  def to_s()
    @path.join("/")
  end # JPath#to_s

  def [](idx)
    @path[idx]
  end

  def dig(name)
    JPath.new(@path + [name])
  end #JPath#dig
end # class JPath

def read_erb(filename)
  File.open(filename) do |f|
    ERB.new(f.read)
  end
end # read_erb

class Worker
  def initialize(outputdir)
    @odir = outputdir
    @repo = []

    @hasherb = read_erb('hash.erb')
    @linkerb = read_erb('link.erb')
    @arrayerb = read_erb('array.erb')
  end # Worker#initialize

  def parse(jvalue, path)
    case jvalue
    when String
      %Q{str("#{jvalue}")}
    when Numeric
      "num(#{jvalue})"
    when NilClass
      "null"
    when TrueClass, FalseClass
      jvalue.to_s
    when Hash
      pairs = []
      jvalue.each do |key, value|
        elem = parse(value, path.dig(key))
        pairs << [key, elem]
      end
      page = @hasherb.result(binding)
      @repo << [path, page]

      href = "./#{path[-1]}/index.html"
      content = "object"
      @linkerb.result(binding)
    when Array
      elems = []
      jvalue.each_with_index do |child, idx|
        elem = parse(child, path.dig(idx.to_s))
        elems << elem
      end
      page = @arrayerb.result(binding)
      @repo << [path, page]

      href = "./#{path[-1]}/index.html"
      content = "array(#{jvalue.length})"
      @linkerb.result(binding)
    end
  end # Worker#parse

  def run(jvalue)
    res = parse(jvalue, JPath.new(["json"]))
    @repo.each do |path, page|
      filepath = path.to_filepath(@odir)
      FileUtils.mkdir_p(File.dirname(filepath))
      File.open(filepath, "w") do |f|
        f.puts page
      end
    end
  end # Worker#run
end # class Worker

if ARGV.length < 2
  puts "requires at least 2 arguments"
  exit
end

inputfile, outputdir = ARGV
worker = Worker.new(outputdir)
worker.run(JSON.parse(File.read(inputfile)))
