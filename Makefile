RUBY?=ruby
RUBY_FLAGS?=-w

all:
	$(RUBY) $(RUBY_FLAGS) test_all.rb

test:
	for f in $$(ls test*.rb|grep -v test_all); do echo testing $$f; $(RUBY) $(RUBY_FLAGS) $$f; done

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
	for rf in demo/*.rb; do f=$$(basename $$rf .rb); rm -f demo/$$f.c demo/$$f; done

