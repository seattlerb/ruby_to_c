RUBY?=ruby
RUBY_FLAGS?=-w

all:
	$(RUBY) $(RUBY_FLAGS) test_all.rb

test:
	$(RUBY) $(RUBY_FLAGS) test_parse_tree.rb
	$(RUBY) $(RUBY_FLAGS) test_unify.rb
	$(RUBY) $(RUBY_FLAGS) test_infer_types.rb
	$(RUBY) $(RUBY_FLAGS) test_ruby_to_c.rb

trouble:
	$(RUBY) $(RUBY_FLAGS) translate.rb zcomparable.rb

c:
	$(MAKE) trouble | tail +2 > trouble.c
	gcc -I/usr/local/lib/ruby/1.8/powerpc-darwin/ -c trouble.c -o trouble.o

clean:
	rm -f *~ trouble.c diff.txt
