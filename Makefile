RUBY?=ruby
RUBY_FLAGS?=-w

all:
	$(RUBY) $(RUBY_FLAGS) test_all.rb

test:
	for f in $$(ls test*.rb|grep -v test_all); do echo testing $$f; $(RUBY) $(RUBY_FLAGS) $$f; done

trouble:
	$(RUBY) $(RUBY_FLAGS) translate.rb zcomparable.rb

c:
	$(MAKE) trouble | tail +2 > trouble.c
	gcc -I/usr/local/lib/ruby/1.8/powerpc-darwin/ -c trouble.c -o trouble.o

clean:
	rm -f *~ trouble.c diff.txt
