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

clean:
	rm -f *~ trouble.* diff.txt
