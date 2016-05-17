RubyToC
=======

[home: https://github.com/seattlerb/ruby_to_c](https://github.com/seattlerb/ruby_to_c)
<br>
[rdoc: http://ruby2c.rubyforge.org/ruby2c](http://ruby2c.rubyforge.org/ruby2c)

DESCRIPTION:
------------

ruby_to_c translates a static ruby subset to C. Hopefully it works.

  NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE
  
  THIS IS BETA SOFTWARE! THIS IS BETA SOFTWARE! THIS IS BETA SOFTWARE!
  
  NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE

RubyToC has the following modules:

* Rewriter - massages the sexp into a more consistent form.
* TypeChecker - type inferencer for the above sexps.
* RubyToRubyC - converts a ruby (subset) sexp to ruby interals C.
* RubyToAnsiC - converts a ruby (subset) sexp to ANSI C.

FEATURES/PROBLEMS:
------------------
  
* This is a preview release! BETA BETA BETA! Do NOT use this!

SYNOPSIS:
---------

```ruby
require 'ruby_parser'
require 'ruby_to_ruby_c'

sexp = RubyParser.new.parse '1 + 1'
c    = RubyToRubyC.new.process sexp
```

TODO:
-----

* Numerous, but we are trying to get them in here... sorry...

REQUIREMENTS:
-------------

* <a href="http://rubyforge.org/projects/parsetree/">ruby_parser - http://rubyforge.org/projects/parsetree</a>

INSTALL:
--------

```bash
sudo gem install ruby2c
```

LICENSE:
--------

```
(The MIT License)

Copyright (c) Ryan Davis, Eric Hodel, seattle.rb

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
