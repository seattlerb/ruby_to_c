#!/usr/local/bin/ruby -ws

$: << "../../ParseTree/dev/lib"

require 'pp'
require 'parse_tree'
require 'ruby_to_ansi_c'

if defined? $h then
  puts "Usage:"
  puts "  #{File.basename $0} [options]"
  puts "    -h display this help"
  puts "    -r display rewriter output only"
  puts "    -t display typecherker output only"
  puts "    -R display r2c rewriter output only"
  puts "    -f fast mode, read from stdin and build class/method around it"
  puts "    -c <class> class to process"
  puts "    -q quick mode, use regular inspect instead of pp"
  puts "    -p print mode, just print instead of p or pp"
  exit 0
end

def discover_new_classes_from
  old_classes = []
  ObjectSpace.each_object(Module) do |klass|
    old_classes << klass
  end

  yield

  new_classes = []
  ObjectSpace.each_object(Module) do |klass|
    new_classes << klass
  end

  new_classes -= old_classes
  new_classes = [ eval($c) ] if defined? $c
  new_classes
end

$f = false unless defined? $f

new_classes = discover_new_classes_from do
  ARGV.unshift "-" if ARGV.empty?
  ARGV.each do |name|
    if name == "-" then
      code = $stdin.read
      code = "class Example; def example; #{code}; end; end" if $f
      eval code unless code.nil?
    else
      require name
    end
  end
end

parser = ParseTree.new(false)
translator = RubyToAnsiC.translator

$r ||= false
$t ||= false
$R ||= false

if $r or $t or $R then
  t = translator.processors
  
  t.pop # r2c
  if $r then
    t.pop # r2c rewriter
    t.pop # typechecker
  end
  if $t then
    t.pop # r2c rewriter
  end
  if $R then
    # nothing else to do
  end
end

new_classes.each do |klass|
  sexp = parser.parse_tree klass
  sexp.each do |exp|
    result = translator.process(exp)

    if defined? $q then
      p result
      next
    end

    if defined? $p then
      puts result
      next
    end

    pp result
  end
end

