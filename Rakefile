# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.add_include_dirs("../../ParseTree/dev/test",
                     "../../ruby_parser/dev/lib",
                     "../../sexp_processor/dev/lib",
                     "../../sexp_processor/dev/test",
                     "lib")

Hoe.plugin :seattlerb

Hoe.spec "ruby2c" do
  developer 'Ryan Davis', 'ryand-ruby@zenspider.com'
  developer 'Eric Hodel', 'drbrain@segment7.net'

  dependency "ruby_parser", "~> 3.0"
  dependency "sexp_processor", "~> 4.1"
end

ENV["MT_NO_EXPECTATIONS"] = "1"

# vim: syntax=ruby
