ruby_to_c
    http://rubyforge.org/projects/ruby2c/
    ryand-ruby@zenspider.com
    ruby2c@zenspider.com - mailing list

NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE

                   THIS IS BETA SOFTWARE!

NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE

DESCRIPTION:
  
RubyToC has the following modules:

	Rewriter      - massages the sexp into a more consistent form.
	TypeChecker   - type inferencer for the above sexps.
	RubyToC       - converts a ruby (subset) sexp to C.

and the following tools:

	translate.rb  - Translates a given file to C.

FEATURES/PROBLEMS:
  
+ This is a preview release! BETA BETA BETA! Do NOT use this!
+ Please contact me or Eric (drbrain of segment7 dot net) if you:
	+ have any feedback!
	+ have any changes!
	+ want to work on this!

SYNOPSYS:

  ./translate.rb blah.rb > blah.c; gcc -c -I /rubylib/1.8/platform blah.c

TODO:

+ Numerous, but we are trying to get them in here... sorry...
+ Want to move to a gem directory structure (lib/ test/ bin/ etc)

REQUIREMENTS:

+ ParseTree - http://rubyforge.org/projects/parsetree/
+ RubyInline - http://rubyforge.org/projects/rubyinline/

INSTALL:

+ Um. Please don't install this crap yet...

LICENSE:

(The MIT License)

Copyright (c) 2001-2002 Ryan Davis, Zen Spider Software

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
