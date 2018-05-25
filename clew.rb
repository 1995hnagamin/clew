require 'erb'
require 'json'

def path2filepath(outputdir, path)
  "#{outputdir}/#{path.join('__')}.html"
end

def path2string(path)
  path.join("/")
end

def json2pages(outputdir, path, repo, jvalue)
  case jvalue
  when String
    [repo, "str:#{jvalue}"]
  when Numeric
    [repo, "num:#{jvalue}"]
  when NilClass
    [repo, "null"]
  when TrueClass, FalseClass
    [repo, jvalue.to_s]
  when Hash
    pairs = []
    jvalue.each do |key, value|
      newpath = path + [key]
      repo, elem = json2pages(outputdir, newpath, repo, value)
      pairs << [key, elem]
    end
    hasherb = File.open('hash.erb') do |f|
      ERB.new(f.read)
    end
    page = hasherb.result(binding)
    repo << [path, page]
    linkerb = File.open('link.erb') do |f|
      ERB.new(f.read)
    end
    content = "object"
    [repo, linkerb.result(binding)]
  when Array
    elems = []
    jvalue.each_with_index do |child, idx|
      newpath = path + [idx.to_s]
      repo, elem = json2pages(outputdir, newpath, repo, child)
      elems << elem
    end
    arrayerb = File.open('array.erb') do |f|
      ERB.new(f.read)
    end
    page = arrayerb.result(binding)
    repo << [path, page]
    linkerb = File.open('link.erb') do |f|
      ERB.new(f.read)
    end
    content = "array(#{jvalue.length})"
    [repo, linkerb.result(binding)]
  end
end

def make_pages(outputdir, jvalue)
  repo, res = json2pages(outputdir, ["json"], [], jvalue)
  repo.each do |path, page|
    filepath = path2filepath(outputdir, path)
    File.open(filepath, "w") do |f|
      f.puts page
    end
  end
end


if ARGV.length < 2
  puts "requires at least 2 arguments"
  exit
end
jfilepath = ARGV[0]
outputdir = ARGV[1]
jvalue = JSON.parse(File.read(jfilepath))
make_pages(outputdir, jvalue)
