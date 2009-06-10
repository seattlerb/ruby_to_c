# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.add_include_dirs("../../ParseTree/dev/lib",
                     "../../ParseTree/dev/test",
                     "../../RubyInline/dev/lib",
                     "../../ruby_parser/dev/lib",
                     "../../ZenTest/dev/lib",
                     "../../sexp_processor/dev/lib",
                     "../../sexp_processor/dev/test",
                     "lib")

require 'ruby_to_ansi_c'

Hoe.spec "RubyToC" do
  developer 'Ryan Davis', 'ryand-ruby@zenspider.com'
  developer 'Eric Hodel', 'drbrain@segment7.net'

  demo_files = Dir["demo/*.rb"].map { |f| File.basename(f, ".rb") }

  clean_globs << File.expand_path("~/.ruby_inline")
  clean_globs.push(*demo_files)
  clean_globs.push(*demo_files.map { |f| f + ".c" })

  extra_deps << "ruby_parser"

  self.testlib = :minitest
end

task :test => :clean

# vim: syntax=Ruby
