RUBY?=ruby
RUBY_FLAGS?=-w -I.:../../ParseTree/dev/lib:../../ParseTree/dev/test:../../RubyInline/dev
TEST?=

all test:
	$(RUBY) $(RUBY_FLAGS) test_all.rb $(TEST)

docs:
	rdoc -d -I png --main RubyToC -x test_\* -x something.rb

VAL=./validate.sh
FILE?=../../ZenTest/dev/TestOrderedHash.rb

valx:
	$(VAL)    $(FILE) > x

val:
	$(VAL) -q $(FILE) | head -20

valno:
	$(VAL)    $(FILE) | grep no:

valstat:
	BAD=$$(wc -l rb.bad.txt | perl -pe 's/\s*(\d+)\s+.*/$$1/'); GOOD=$$(wc -l rb.good.txt | perl -pe 's/\s*(\d+)\s+.*/$$1/'); echo "1 - $$BAD / ($$GOOD + $$BAD)" | bc -l

valoccur:
	egrep "ERROR|no:" rb.err.txt | perl -pe 's/ in .*//; s/(translating \S+):/$$1/; s/(is not an Array \w+):.*/$$1/; s/.* (is not a supported node type)/blah $$1/; s/(Unable to unify).*/$$1/; s/(Unknown literal) \S+/$$1/;' | occur 

trouble: trouble.o
	@exit 0

trouble.o: trouble.c
	gcc -I/usr/local/lib/ruby/1.8/powerpc-darwin/ -c trouble.c -o trouble.o

trouble.c: zcomparable.rb translate.rb ruby_to_c.rb type_checker.rb
	$(RUBY) $(RUBY_FLAGS) translate.rb zcomparable.rb > trouble.c

FORCE:
demos: FORCE
	for rf in demo/*.rb; do f=$$(basename $$rf .rb); echo $$f; ./translate.rb demo/$$f > demo/$$f.c && gcc -Iinc -o demo/$$f demo/$$f.c; done

interp: FORCE
	for rf in demo/*.rb; do f=$$(basename $$rf .rb); echo $$f; ./interp.rb demo/$$f; done

clean:
	rm -f *~ trouble.* diff.txt demo/*~
	rm -rf ~/.ruby_inline
	for rf in demo/*.rb; do f=$$(basename $$rf .rb); rm -f demo/$$f.c demo/$$f; done

