# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.add_include_dirs("../../ParseTree/dev/lib",
                     "../../ParseTree/dev/test",
                     "../../RubyInline/dev/lib",
                     "../../ruby_parser/dev/lib",
                     "../../sexp_processor/dev/lib",
                     "../../sexp_processor/dev/test",
                     "lib")

require 'ruby_to_ansi_c'

Hoe.new("RubyToC", RubyToAnsiC::VERSION.sub(/-beta-/, '.')) do |r2c|
  r2c.developer('Ryan Davis', 'ryand-ruby@zenspider.com')
  r2c.developer('Eric Hodel', 'drbrain@segment7.net')

  demo_files = Dir["demo/*.rb"].map { |f| File.basename(f, ".rb") }

  r2c.clean_globs << File.expand_path("~/.ruby_inline")
  r2c.clean_globs.push(*demo_files)
  r2c.clean_globs.push(*demo_files.map { |f| f + ".c" })

  r2c.extra_deps << "ParseTree"
end

task :test => :clean

# vim: syntax=Ruby
