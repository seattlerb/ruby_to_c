#!/usr/local/bin/ruby -w

Dir.glob("test_*.rb").each do |f|
  require f
end

require 'test/unit'
