ruby_to_c
    http://www.zenspider.com/
    ryand-ruby@zenspider.com

NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE

                   THIS IS ALPHA SOFTWARE!

NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE ! NOTE


DESCRIPTION:
  
RubyToC has the following modules:

	SexpProcessor - a generic sexp processor.
	ParseTree     - converts ruby's internal parse tree to a sexp.
	Rewriter      - massages the sexp into a more consistent form.
	TypeChecker   - type inferencer for the above sexps.
	RubyToC       - converts a ruby (subset) sexp to C.

and the following tools:

	show.rb       - Displays the sexp for a given file.
	translate.rb  - Translates a given file to C.

FEATURES/PROBLEMS:
  
+ This is a preview release! ALPHA ALPHA ALPHA! Do NOT use this!
+ Please contact me if you have any feedback!
+ Please contact me if you have any changes!
+ Please contact me if you want to work on this!
+ Please do _NOT_ contact me if you want to speed up your ruby code!
  That is not the intent of this project. See RubyInline if that is
  your goal.

SYNOPSYS:

  ./translate.rb blah.rb > blah.c; gcc -c -I /rubylib/1.8/platform blah.c

REQUIREMENTS:

+ RubyInline 3 - http://sourceforge.net/projects/rubyinline/

INSTALL:

+ Um. Please don't install this crap yet. We just want feedback at this stage.

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
