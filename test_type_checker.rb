#!/usr/local/bin/ruby -w

$TESTING = true

require 'test/unit'
require 'type_checker'
require 'something'

# Test::Unit::Assertions.use_pp = false

class TestTypeChecker < Test::Unit::TestCase

  def setup
    @type_checker = TypeChecker.new
  end

  def test_and
    input  = t(:and, t(:true), t(:false))
    output = t(:and, t(:true, Type.bool), t(:false, Type.bool), Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_bootstrap
    # bootstrap is automatically called by initialize
    # TODO should we check for EVERYTHING we expect?

    assert_equal Type.file, @type_checker.genv.lookup(:$stdin)
    assert_equal Type.file, @type_checker.genv.lookup(:$stdout)
    assert_equal Type.file, @type_checker.genv.lookup(:$stderr)

    assert_equal(Type.function(Type.long, [Type.long], Type.bool),
                 @type_checker.functions[:>])
  end

  def test_functions
    # bootstrap populates functions
    assert @type_checker.functions.has_key?(:puts)
    assert_equal(Type.function(Type.long, [Type.long], Type.bool),
                 @type_checker.functions[:>])
  end

  def test_env
    @type_checker.env.add :blah, Type.long
    assert_equal Type.long, @type_checker.env.lookup(:blah) 
 end

  def test_genv
    assert_equal Type.file, @type_checker.genv.lookup(:$stderr)
  end

  def test_translate
    result = @type_checker.translate Something, :empty
    expect = t(:defn,
               :empty,
               t(:args),
               t(:scope,
                 t(:block,
                   t(:nil, Type.value), Type.unknown), Type.void),
               Type.function(Type.unknown, [], Type.void))
    assert_equal(expect, result)
  end

  def test_process_args
    @type_checker.env.extend

    input =  t(:args, :foo, :bar)
    output = t(:args,
               t(:foo, Type.unknown),
               t(:bar, Type.unknown))

    assert_equal output, @type_checker.process(input)
  end

  def test_process_args_empty
    input =  t(:args)
    output = t(:args)
    # TODO: this should be superseded by the new array functionality

    assert_equal output, @type_checker.process(input)
  end

  def test_process_array_single
    add_fake_var :arg1, Type.long

    input  = t(:array, t(:lvar, :arg1))
    output = t(:array, t(:lvar, :arg1, Type.long))

    result = @type_checker.process(input)

    assert_equal Type.homo, result.sexp_type    
    assert_equal [ Type.long ], result.sexp_types
    assert_equal output, result
  end

  def test_process_array_multiple
    add_fake_var :arg1, Type.long
    add_fake_var :arg2, Type.str

    input =  t(:array, t(:lvar, :arg1), t(:lvar, :arg2))
    output = t(:array,
               t(:lvar, :arg1, Type.long),
               t(:lvar, :arg2, Type.str))

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_defined
    add_fake_function :name, Type.void, Type.long, Type.str
    input  = t(:call,
               nil,
               :name,
               t(:array, t(:str, "foo")))
    output = t(:call,
               nil,
               :name,
               t(:array, t(:str, "foo", Type.str)),
               Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_defined_rhs
    add_fake_function :name3, Type.long, Type.long, Type.str
    input  = t(:call,
               t(:lit, 1),
               :name3,
               t(:array, t(:str, "foo")))
    output = t(:call,
               t(:lit, 1, Type.long),
               :name3,
               t(:array, t(:str, "foo", Type.str)),
               Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_undefined
    input  = t(:call, nil, :name, nil)
    output = t(:call, nil, :name, nil, Type.unknown)

    assert_equal output, @type_checker.process(input)
    # FIX returns unknown in s()
    assert_equal(Type.function(Type.unknown, [], Type.unknown),
                 @type_checker.functions[:name])
  end

  def test_process_call_unify_1
    add_fake_var :number, Type.long
    input  = t(:call,
               t(:lit, 1),
               :==,
               t(:array,
                 t(:lvar, :number)))
    output = t(:call,
               t(:lit, 1, Type.long),
               :==,
               t(:array,
                 t(:lvar, :number, Type.long)),
               Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_unify_2
    add_fake_var :number1, Type.unknown
    add_fake_var :number2, Type.unknown

    input  = t(:call,
               t(:lit, 1),
               :==,
               t(:array, t(:lvar, :number1)))
    output = t(:call,
               t(:lit, 1, Type.long),
               :==,
               t(:array,
                 t(:lvar, :number1, Type.long)),
               Type.bool)

    assert_equal output, @type_checker.process(input)

    input  = t(:call,
               t(:lvar, :number2),
               :==,
               t(:array, t(:lit, 1)))
    output = t(:call,
               t(:lvar, :number2, Type.long),
               :==,
               t(:array,
                 t(:lit, 1, Type.long)),
               Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_unify_3
    a_type = Type.unknown
    add_fake_var :a, a_type # TODO: Type.unknown

    # def unify_3_outer(a)
    #
    #             unk
    #              ^
    #              |
    # outer(., ., [+])

    # assume the environment got everything set up correctly
    add_fake_function(:unify_3_outer, Type.void, Type.void, a_type)

    assert_equal(a_type,
                 @type_checker.functions[:unify_3_outer].list_type.formal_types[0])

    #   unify_3_inner(a) # call
    #
    # outer(., ., [+])
    #              |
    #              v
    #             unk
    #              ^
    #              |
    # inner(., ., [+])

    @type_checker.process(t(:call, t(:nil),
                            :unify_3_inner,
                            t(:array, t(:lvar, :a))))

    assert_equal a_type, @type_checker.env.lookup(:a)
    assert_equal(@type_checker.env.lookup(:a),
                 @type_checker.functions[:unify_3_inner].list_type.formal_types[0])
    
    # def unify_3_inner(a)
    #   a = 1
    # end
    #
    # outer(., ., [+])
    #              |
    #              v
    #             long
    #              ^
    #              |
    # inner(., ., [+])

    @type_checker.env.scope do
      @type_checker.env.add :a, a_type
      
      @type_checker.process t(:lasgn, :a, t(:lit, 1))
    end

    assert_equal a_type, Type.long

    assert_equal(@type_checker.functions[:unify_3_inner].list_type.formal_types[0],
                 @type_checker.functions[:unify_3_outer].list_type.formal_types[0])
  end

  def test_defn_call_unify

    # pre-registered function, presumibly through another :call elsewhere
    add_fake_function :specific, Type.unknown, Type.unknown, Type.unknown

    # now in specific, unify with a long
# puts "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# pp @type_checker.functions
    s = @type_checker.process(s(:defn, :specific,
                                s(:args, :x),
                                s(:scope,
                                  s(:block,
                                    s(:lasgn, :x, s(:lit, 2))))))
# pp @type_checker.functions
    s_type = @type_checker.functions[:specific]

# p s_type

    assert_equal(Type.long,
                 s_type.list_type.formal_types[0])
# HACK    flunk "eric hasn't finished writing me yet. guilt. guilt. guilt."
  end

  def test_process_call_case_equal_long
    add_fake_var :number, Type.unknown

    input  = t(:call,
               t(:lit, 1),
               :===,
               t(:array, t(:lvar, :number)))
    output = t(:call,
               t(:lit, 1, Type.long),
               :case_equal_long,
               t(:array,
                 t(:lvar, :number, Type.long)),
               Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_case_equal_string
    add_fake_var :string, Type.unknown

    input  = t(:call,
               t(:str, 'foo'),
               :===,
               t(:array, t(:lvar, :string)))
    output = t(:call,
               t(:str, 'foo', Type.str),
               :case_equal_str,
               t(:array,
                 t(:lvar, :string, Type.str)),
               Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_class
    input = s(:class, :X, :Object,
              s(:defn, :meth,
                s(:args, :x),
                s(:scope,
                  s(:block,
                    s(:lasgn, :x, s(:lit, 2))))))
    output = t(:class, :X, :Object,
               t(:defn, :meth,
                 t(:args, t(:x, Type.long)),
                 t(:scope,
                   t(:block,
                     t(:lasgn, :x,
                       t(:lit, 2, Type.long),
                       Type.long),
                     Type.unknown),
                   Type.void),
                 Type.function(Type.unknown, [Type.long], Type.void)),
               Type.zclass)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_const
    assert_raises NameError do
      @type_checker.process s(:const, :NonExistant)
    end
  end

  def test_process_block
    input  = t(:block, t(:return, t(:nil)))
    # FIX: should this really be void for return?
    output = t(:block,
               t(:return,
                 t(:nil, Type.value),
                 Type.void),
               Type.unknown)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_block_multiple
    input  = t(:block,
               t(:str, :foo),
               t(:return, t(:nil)))
    output = t(:block,
               t(:str, :foo, Type.str),
               t(:return,
                 t(:nil, Type.value),
                 Type.void),
               Type.unknown)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_dasgn_curr
    @type_checker.env.extend
    input  = t(:dasgn_curr, :x)
    output = t(:dasgn_curr, :x, Type.unknown)

    assert_equal output, @type_checker.process(input)
    # HACK: is this a valid test??? it was in ruby_to_c:
    # assert_equal Type.long, @type_checker.env.lookup(:x)
  end

  def test_process_defn
    function_type = Type.function s(), Type.void
    input  = t(:defn,
               :empty,
               t(:args),
               t(:scope))
    output = t(:defn,
               :empty,
               t(:args),
               t(:scope, Type.void),
               function_type)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_dstr
    add_fake_var :var, Type.str
    input  = t(:dstr,
               "var is ",
               t(:lvar, :var),
               t(:str, ". So there."))
    output = t(:dstr, "var is ",
               t(:lvar, :var, Type.str),
               t(:str, ". So there.", Type.str),
               Type.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_dvar
    add_fake_var :dvar, Type.long
    input  = t(:dvar, :dvar)
    output = t(:dvar, :dvar, Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_false
    input =   t(:false)
    output = t(:false, Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_gvar_defined
    add_fake_gvar :$arg, Type.long
    input  = t(:gvar, :$arg)
    output = t(:gvar, :$arg, Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_gvar_undefined
    input  = t(:gvar, :$arg)
    output = t(:gvar, :$arg, Type.unknown)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_if
    input  = t(:if,
               t(:call,
                 t(:lit, 1),
                 :==,
                 t(:array, t(:lit, 2))),
               t(:str, "not equal"),
               nil)
    output = t(:if,
               t(:call,
                 t(:lit, 1, Type.long),
                 :==,
                 t(:array,
                   t(:lit, 2, Type.long)),
                 Type.bool),
               t(:str, "not equal", Type.str),
               nil,
               Type.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_if_else
    input  = t(:if,
               t(:call,
                 t(:lit, 1),
                 :==,
                 t(:array, t(:lit, 2))),
               t(:str, "not equal"),
               t(:str, "equal"))
    output = t(:if,
               t(:call,
                 t(:lit, 1, Type.long),
                 :==,
                 t(:array, t(:lit, 2, Type.long)),
                 Type.bool),
               t(:str, "not equal", Type.str),
               t(:str, "equal", Type.str),
               Type.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_iter
    @type_checker.env.extend
    var_type = Type.long_list
    add_fake_var :array, var_type
    input  = t(:iter,
               t(:call,
                 t(:lvar, :array),
                 :each,
                 nil),
               t(:dasgn_curr, :x),
               t(:call,
                 nil,
                 :puts,
                 t(:array,
                   t(:call,
                     t(:dvar, :x),
                     :to_s,
                     nil))))
    output = t(:iter,
               t(:call,
                 t(:lvar, :array, var_type),
                 :each,
                 nil,
                 Type.unknown),
               t(:dasgn_curr, :x, Type.long),
               t(:call,
                 nil,
                 :puts,
                 t(:array,
                   t(:call,
                     t(:dvar, :x, Type.long),
                     :to_s,
                     nil,
                     Type.str)),
                 Type.void),
               Type.void)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_lasgn
    @type_checker.env.extend # FIX: this is a design flaw... examine irb sess:
    # require 'sexp_processor'
    # require 'type_checker'
    # tc = TypeChecker.new
    # s = t(:lasgn, :var, t(:str, "foo"))
    # tc.process(s)
    # => raises
    # tc.env.extend
    # tc.process(s)
    # => raises elsewhere... etc etc etc
    # makes debugging very difficult
    input  = t(:lasgn, :var, t(:str, "foo"))
    output = t(:lasgn, :var, 
               t(:str, "foo", Type.str),
               Type.str)

    assert_equal output, @type_checker.process(input)
  end
  
  def test_process_lasgn_array
    @type_checker.env.extend
    input  = t(:lasgn,
               :var,
               t(:array,
                 t(:str, "foo"),
                 t(:str, "bar")))
    output = t(:lasgn, :var,
               t(:array,
                 t(:str, "foo", Type.str),
                 t(:str, "bar", Type.str)),
               Type.str_list)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_lit
    input  = t(:lit, 1)
    output = t(:lit, 1, Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_lvar
    add_fake_var :arg, Type.long
    input  = t(:lvar, :arg)
    output = t(:lvar, :arg, Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_nil
    input  = t(:nil)
    output = t(:nil, Type.value)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_not
    input  = t(:not, t(:true))
    output = t(:not, t(:true, Type.bool), Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_or
    input  = t(:or, t(:true), t(:false))
    output = t(:or, t(:true, Type.bool), t(:false, Type.bool), Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_rescue
    assert_raises RuntimeError do
      @type_checker.process s(:rescue, s(:true), s(:true))
    end
  end

  def test_process_return
    input  = t(:return, t(:nil))
    output = t(:return, t(:nil, Type.value), Type.void)

    assert_equal output, @type_checker.process(input)
  end

# HACK is this test valid? I don't think so
#  def test_process_return_empty
#    input  = t(:return)
#    output = t(:return, t(:nil, Type.value), Type.void)
#
#    assert_equal output, @type_checker.process(input)
#  end

  def test_process_str
    input  = t(:str, "foo")
    output = t(:str, "foo", Type.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_scope
    input  = t(:scope,
               t(:block,
                 t(:return, t(:nil))))
    output = t(:scope,
               t(:block,
                 t(:return,
                   t(:nil, Type.value),
                   Type.void),
                 Type.unknown), # FIX ? do we care about block?
               Type.void)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_scope_empty
    input =   t(:scope)
    output = t(:scope, Type.void)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_true
    input =  t(:true)
    output = t(:true, Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_unless
    input  = t(:if,
               t(:call,
                 t(:lit, 1),
                 :==,
                 t(:array, t(:lit, 2))),
               nil,
               t(:str, "equal"))
    output = t(:if,
               t(:call,
                 t(:lit, 1, Type.long),
                 :==, 
                 t(:array,
                   t(:lit, 2, Type.long)),
                 Type.bool),
               nil,
               t(:str, "equal", Type.str),
               Type.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_while
    input    = t(:while, t(:true), t(:call, t(:lit, 1), :to_s, nil))
    expected = t(:while,
                 t(:true, Type.bool),
                 t(:call, t(:lit, 1, Type.long), :to_s, nil,
                   Type.str))

    assert_equal expected, @type_checker.process(input)
  end

  def add_fake_function(name, reciever_type, return_type, *arg_types)
    @type_checker.functions.add_function(name,
                                         Type.function(reciever_type, arg_types, return_type))
  end

  def add_fake_var(name, type)
    @type_checker.env.extend
    @type_checker.env.add name, type
  end

  def add_fake_gvar(name, type)
    @type_checker.genv.add name, type
  end

end

class TestTypeChecker_2 < Test::Unit::TestCase # ZenTest SKIP

  # TODO: need a good test of interpolated strings
  @@missing = s(nil)

  @@empty = t(:defn, :empty,
              t(:args),
              t(:scope,
                t(:block,
                  t(:nil, Type.value), Type.unknown), Type.void),
              Type.function(Type.unknown, [], Type.void))

  @@stupid = t(:defn, :stupid,
               t(:args),
               t(:scope,
                 t(:block,
                   t(:return,
                     t(:nil, Type.value),
                     Type.void),
                   Type.unknown),
                 Type.void),
               Type.function(Type.unknown, [], Type.value))

  @@simple = t(:defn, :simple,
               t(:args, t(:arg1, Type.str)),
               t(:scope,
                 t(:block,
                   t(:call,
                     nil,
                     :print,
                     t(:array,
                       t(:lvar,
                         :arg1,
                         Type.str)),
                     Type.void),
                   t(:call,
                     nil,
                     :puts,
                     t(:array,
                       t(:call,
                         t(:call,
                           t(:lit, 4, Type.long),
                           :+,
                           t(:array,
                             t(:lit, 2, Type.long)),
                           Type.long),
                         :to_s,
                         nil, Type.str)),
                     Type.void),
                   Type.unknown),
                 Type.void),
               Type.function(Type.unknown, [Type.str], Type.void)) # HACK - receiver shouldn't be unknown

  @@global = t(:defn, :global,
               t(:args),
               t(:scope,
                 t(:block,
                   t(:call,
                     t(:gvar, :$stderr, Type.file),
                     :fputs,
                     t(:array,
                       t(:str, "blah", Type.str)),
                     Type.unknown),
                   Type.unknown),
                 Type.void),
               Type.function(Type.unknown, [], Type.void))

  @@lasgn_call = t(:defn, :lasgn_call,
                   t(:args),
                   t(:scope,
                     t(:block,
                       t(:lasgn, :c,
                         t(:call,
                           t(:lit, 2, Type.long),
                           :+,
                           t(:array,
                             t(:lit, 3, Type.long)),
                           Type.long),
                         Type.long),
                       Type.unknown),
                     Type.void),
                   Type.function(Type.unknown, [], Type.void))

  @@conditional1 = 
    t(:defn, :conditional1,
      t(:args, t(:arg1, Type.long)),
      t(:scope,
        t(:block,
          t(:if,
            t(:call,
              t(:lvar, :arg1, Type.long),
              :==,
              t(:array,
                t(:lit, 0, Type.long)),
              Type.bool),
            t(:return,
              t(:lit, 1, Type.long),
              Type.void),
            nil, Type.void), Type.unknown), Type.void),
      Type.function(Type.unknown, [Type.long], Type.long))

  @@conditional2 = t(:defn, :conditional2,
                     t(:args, t(:arg1, Type.long)),
                     t(:scope,
                       t(:block,
                         t(:if,
                           t(:call,
                             t(:lvar, :arg1, Type.long),
                             :==,
                             t(:array,
                               t(:lit, 0, Type.long)),
                             Type.bool),
                           nil,
                           t(:return,
                             t(:lit, 2, Type.long),
                             Type.void),
                           Type.void),
                         Type.unknown),
                       Type.void),
                     Type.function(Type.unknown, [Type.long], Type.long))

  @@conditional3 = t(:defn, :conditional3,
                     t(:args, t(:arg1, Type.long)),
                     t(:scope,
                       t(:block,
                         t(:if,
                           t(:call,
                             t(:lvar, :arg1, Type.long),
                             :==,
                             t(:array,
                               t(:lit, 0, Type.long)),
                             Type.bool),
                           t(:return,
                             t(:lit, 3, Type.long),
                             Type.void),
                           t(:return,
                             t(:lit, 4, Type.long),
                             Type.void),
                           Type.void),
                         Type.unknown),
                       Type.void),
                     Type.function(Type.unknown, [Type.long], Type.long))

  @@conditional4 = t(:defn, :conditional4,
                     t(:args, t(:arg1, Type.long)),
                     t(:scope,
                       t(:block,
                         t(:if,
                           t(:call,
                             t(:lvar, :arg1, Type.long),
                             :==,
                             t(:array,
                               t(:lit, 0, Type.long)),
                             Type.bool),
                           t(:return,
                             t(:lit, 2, Type.long),
                             Type.void),
                           t(:if,
                             t(:call,
                               t(:lvar, :arg1, Type.long),
                               :<,
                               t(:array,
                                 t(:lit, 0, Type.long)),
                               Type.bool),
                             t(:return,
                               t(:lit, 3, Type.long),
                               Type.void),
                             t(:return,
                               t(:lit, 4, Type.long),
                               Type.void),
                             Type.void),
                           Type.void),
                         Type.unknown),
                       Type.void),
                     Type.function(Type.unknown, [Type.long], Type.long))

  @@__iteration_body = [
    t(:args),
    t(:scope,
      t(:block,
        t(:lasgn, :array,
          t(:array,
            t(:lit, 1, Type.long),
            t(:lit, 2, Type.long),
            t(:lit, 3, Type.long)),
          Type.long_list),
        t(:iter,
          t(:call,
            t(:lvar, :array, Type.long_list),
            :each,
            nil, Type.unknown),
          t(:dasgn_curr, :x, Type.long),
          t(:call,
            nil,
            :puts,
            t(:array,
              t(:call,
                t(:dvar, :x, Type.long),
                :to_s,
                nil,
                Type.str)),
            Type.void),
          Type.void),
        Type.unknown),
      Type.void),
    Type.function(Type.unknown, [], Type.void)]

  @@iteration1 = t(:defn, :iteration1, *@@__iteration_body)

  @@iteration2 = t(:defn, :iteration2, *@@__iteration_body)

  @@iteration3 = t(:defn, :iteration3,
                   t(:args),
                   t(:scope,
                     t(:block,
                       t(:lasgn, :array1,
                         t(:array,
                           t(:lit, 1, Type.long),
                           t(:lit, 2, Type.long),
                           t(:lit, 3, Type.long)),
                         Type.long_list),
                       t(:lasgn, :array2,
                         t(:array,
                           t(:lit, 4, Type.long),
                           t(:lit, 5, Type.long),
                           t(:lit, 6, Type.long),
                           t(:lit, 7, Type.long)),
                         Type.long_list),
                       t(:iter,
                         t(:call,
                           t(:lvar, :array1, Type.long_list),
                           :each,
                           nil,
                           Type.unknown),
                         t(:dasgn_curr, :x, Type.long),
                         t(:iter,
                           t(:call,
                             t(:lvar, :array2, Type.long_list),
                             :each,
                             nil,
                             Type.unknown),
                           t(:dasgn_curr, :y, Type.long),
                           t(:block,
                             t(:call,
                               nil,
                               :puts,
                               t(:array,
                                 t(:call,
                                   t(:dvar, :x, Type.long),
                                   :to_s,
                                   nil,
                                   Type.str)),
                               Type.void),
                             t(:call,
                               nil,
                               :puts,
                               t(:array,
                                 t(:call,
                                   t(:dvar, :y, Type.long),
                                   :to_s,
                                   nil,
                                   Type.str)),
                               Type.void),
                             Type.unknown),
                           Type.void),
                         Type.void),
                       Type.unknown),
                     Type.void),
                   Type.function(Type.unknown, [], Type.void))

  @@iteration4 = t(:defn,
                   :iteration4,
                   t(:args),
                   t(:scope,
                     t(:block,
                       t(:dummy,
                       t(:lasgn, :n, t(:lit, 1, Type.long), Type.long),
                       t(:while,
                         t(:call,
                           t(:lvar, :n, Type.long),
                           :<=,
                           t(:array, t(:lit, 3, Type.long)), Type.bool),
                         t(:block,
                           t(:call,
                             nil,
                             :puts,
                             t(:array,
                               t(:call,
                                 t(:lvar, :n, Type.long),
                                 :to_s,
                                 nil, Type.str)), Type.void),
                           t(:lasgn,
                             :n,
                             t(:call,
                               t(:lvar, :n, Type.long),
                               :+,
                               t(:array,
                                 t(:lit,
                                   1, Type.long)), Type.long), Type.long), Type.unknown))), Type.unknown), Type.void),
                   Type.function(Type.unknown, [], Type.void))
  @@iteration5 = t(:defn,
                   :iteration5,
                   t(:args),
                   t(:scope,
                     t(:block,
                       t(:dummy,
                         t(:lasgn, :n, t(:lit, 3, Type.long), Type.long),
                         t(:while,
                           t(:call,
                             t(:lvar, :n, Type.long),
                             :>=,
                             t(:array, t(:lit, 1, Type.long)), Type.bool),
                           t(:block,
                             t(:call,
                               nil,
                               :puts,
                               t(:array,
                                 t(:call,
                                   t(:lvar, :n, Type.long),
                                   :to_s,
                                   nil, Type.str)), Type.void),
                             t(:lasgn,
                               :n,
                               t(:call,
                                 t(:lvar, :n, Type.long),
                                 :-,
                                 t(:array,
                                   t(:lit,
                                     1, Type.long)),
                                 Type.long),
                               Type.long),
                           Type.unknown))),
                       Type.unknown),
                     Type.void),
                   Type.function(Type.unknown, [], Type.void))

  @@iteration6 = t(:defn,
                   :iteration6,
                   t(:args),
                   t(:scope,
                     t(:block,
                       t(:dummy,
                         t(:lasgn,
                           :temp_var1,
                           t(:lit, 3, Type.long), Type.long),
                         t(:while,
                           t(:call, t(:lvar, :temp_var1, Type.long),
                           :>=,
                           t(:array, t(:lit, 1, Type.long)), Type.bool),
                           t(:block,
                             t(:call, nil, :puts,
                               t(:array, t(:str, "hello", Type.str)),
                             Type.void),
                             t(:lasgn,
                               :temp_var1,
                               t(:call, t(:lvar, :temp_var1, Type.long),
                               :-,
                               t(:array, t(:lit, 1, Type.long)), Type.long),
                                 Type.long),
                         Type.unknown))),
                       Type.unknown),
                     Type.void),
                   Type.function(Type.unknown, [], Type.void))

  @@multi_args = t(:defn, :multi_args,
                   t(:args,
                     t(:arg1, Type.long),
                     t(:arg2, Type.long)),
                   t(:scope,
                     t(:block,
                       t(:lasgn,
                         :arg3,
                         t(:call,
                           t(:call,
                             t(:lvar, :arg1, Type.long),
                             :*,
                             t(:array,
                               t(:lvar,
                                 :arg2,
                                 Type.long)),
                             Type.long),
                           :*,
                           t(:array,
                             t(:lit, 7, Type.long)),
                           Type.long),
                         Type.long),
                       t(:call,
                         nil,
                         :puts,
                         t(:array,
                           t(:call,
                             t(:lvar, :arg3, Type.long),
                             :to_s,
                             nil,
                             Type.str)),
                         Type.void),
                       t(:return, t(:str, "foo", Type.str),
                         Type.void),
                       Type.unknown),
                     Type.void),
                   Type.function(Type.unknown, [Type.long, Type.long], Type.str))

  # TODO: why does return false have type void?
  @@bools = t(:defn, :bools,
              t(:args, t(:arg1, Type.value)),
              t(:scope,
                t(:block,
                  t(:if,
                    t(:call,
                      t(:lvar, :arg1, Type.value),
                      :nil?,
                      nil,
                      Type.bool),
                    t(:return,
                      t(:false, Type.bool),
                      Type.void),
                    t(:return,
                      t(:true, Type.bool),
                      Type.void),
                    Type.void),
                  Type.unknown),
                Type.void),
              Type.function(Type.unknown, [Type.value], Type.bool))

  @@case_stmt = t(:defn, :case_stmt,
                  t(:args),
                  t(:scope,
                    t(:block,
                      t(:lasgn,
                        :var,
                        t(:lit, 2, Type.long),
                        Type.long),
                      t(:lasgn,
                        :result,
                        t(:str, "", Type.str),
                        Type.str),
                      t(:if,
                        t(:call,
                          t(:lvar, :var, Type.long),
                          :case_equal_long,
                          t(:array, t(:lit, 1, Type.long)),
                          Type.bool),
                        t(:block,
                          t(:call,
                            nil,
                            :puts,
                            t(:array,
                              t(:str, "something", Type.str)),
                            Type.void),
                          t(:lasgn,
                            :result,
                            t(:str, "red", Type.str),
                            Type.str),
                          Type.str),
                        t(:if,
                          t(:or,
                            t(:call,
                              t(:lvar, :var, Type.long),
                              :case_equal_long,
                              t(:array, t(:lit, 2, Type.long)),
                              Type.bool),
                            t(:call,
                              t(:lvar, :var, Type.long),
                              :case_equal_long,
                              t(:array, t(:lit, 3, Type.long)),
                              Type.bool),
                            Type.bool),
                          t(:lasgn,
                            :result,
                            t(:str, "yellow", Type.str),
                            Type.str),
                          t(:if,
                            t(:call,
                              t(:lvar, :var, Type.long),
                              :case_equal_long,
                              t(:array, t(:lit, 4, Type.long)),
                              Type.bool),
                            nil,
                            t(:lasgn,
                              :result,
                              t(:str, "green", Type.str),
                              Type.str),
                            Type.str),
                          Type.str),
                        Type.str),
                      t(:if,
                        t(:call,
                          t(:lvar, :result, Type.str),
                          :case_equal_str,
                          t(:array, t(:str, "red", Type.str)),
                          Type.bool),
                        t(:lasgn, :var, t(:lit, 1, Type.long), Type.long),
                        t(:if,
                          t(:call,
                            t(:lvar, :result, Type.str),
                            :case_equal_str,
                            t(:array, t(:str, "yellow", Type.str)),
                            Type.bool),
                          t(:lasgn, :var, t(:lit, 2, Type.long), Type.long),
                          t(:if,
                            t(:call,
                              t(:lvar, :result, Type.str),
                              :case_equal_str,
                              t(:array,
                                t(:str, "green", Type.str)),
                              Type.bool),
                            t(:lasgn,
                              :var,
                              t(:lit, 3, Type.long),
                              Type.long),
                            nil,
                            Type.long),
                          Type.long),
                        Type.long),
                      t(:return,
                        t(:lvar, :result, Type.str),
                        Type.void),
                      Type.unknown),
                    Type.void),
                  Type.function(Type.unknown, [], Type.str))

  @@eric_is_stubborn = t(:defn,
                         :eric_is_stubborn,
                         t(:args),
                         t(:scope,
                           t(:block,
                             t(:lasgn,
                               :var,
                               t(:lit,
                                 42,
                                 Type.long),
                               Type.long),
                             t(:lasgn,
                               :var2,
                               t(:call,
                                 t(:lvar, :var, Type.long),
                                 :to_s,
                                 nil,
                                 Type.str),
                               Type.str),
                             t(:call,
                               t(:gvar,
                                 :$stderr,
                                 Type.file),
                               :fputs,
                               t(:array,
                                 t(:lvar, :var2, Type.str)),
                               Type.unknown),
                             t(:return,
                               t(:lvar, :var2, Type.str),
                               Type.void),
                             Type.unknown),
                           Type.void),
                         Type.function(Type.unknown, [], Type.str))

  @@interpolated = t(:defn,
                     :interpolated,
                     t(:args),
                     t(:scope,
                       t(:block,
                         t(:lasgn,
                           :var,
                           t(:lit,
                             14,
                             Type.long),
                           Type.long),
                         t(:lasgn, :var2,
                           t(:dstr,
                             "var is ",
                             t(:lvar, :var, Type.long),
                             t(:str, ". So there.", Type.str),
                             Type.str),
                           Type.str),
                         Type.unknown),
                       Type.void),
                     Type.function(Type.unknown, [], Type.void))

  @@unknown_args = t(:defn, :unknown_args,
                     t(:args,
                       t(:arg1, Type.long),
                       t(:arg2, Type.str)),
                     t(:scope,
                       t(:block,
                         t(:return,
                           t(:lvar,
                             :arg1,
                             Type.long),
                           Type.void),
                         Type.unknown),
                       Type.void),
                     Type.function(Type.unknown, [Type.long, Type.str], Type.long))

  @@determine_args = t(:defn, :determine_args,
                       t(:args),
                       t(:scope,
                         t(:block,
                           t(:call,
                             t(:lit,
                               5,
                               Type.long),
                             :==,
                             t(:array,
                               t(:call,
                                 nil,
                                 :unknown_args,
                                 t(:array,
                                   t(:lit, 4, Type.long),
                                   t(:str, "known", Type.str)),
                                 Type.long)),
                             Type.bool),
                           Type.unknown),
                         Type.void),
                       Type.function(Type.unknown, [], Type.void))

  @@zarray = t(:defn,
               :zarray,
               t(:args),
               t(:scope,
                 t(:block,
                   t(:lasgn,
                     :a,
                     t(:array), Type.unknown_list),
                   Type.unknown),
                 Type.void),
               Type.function(Type.unknown, [], Type.void))

  @@tempresbody = nil
  @@bmethod_added = t(:defn, :bmethod_added,
                      t(:args, t(:x, Type.long)),
                      t(:scope,
                        t(:block,
                          t(:call,
                            t(:lvar, :x, Type.long),
                            :+,
                            t(:array,
                              t(:lit,
                                1, Type.long)),
                            Type.long),
                          Type.unknown),
                        Type.void),
                      Type.function(Type.unknown, [Type.long], Type.void))
  @@dmethod_added = t(:defn,
                      :dmethod_added,
                      t(:args, t(:x, Type.long)),
                      t(:scope,
                        t(:block,
                          t(:call,
                            t(:lvar, :x, Type.long),
                            :+,
                            t(:array,
                              t(:lit,
                                1, Type.long)),
                            Type.long),
                          Type.unknown),
                        Type.void),
                      Type.function(Type.unknown, [Type.long], Type.void))

  # TODO: sort all vars

  @@bbegin = t(:defn, :bbegin,
               t(:args),
               t(:scope,
                 t(:block,
                   t(:begin,
                     t(:ensure,
                       t(:rescue,
                         t(:call,
                           t(:lit, 1, Type.long),
                           :+,
                           t(:array, t(:lit, 1, Type.long)), Type.long),
                         t(:resbody,
                           t(:array, t(:const, :SyntaxError, Type.fucked)),
                           t(:block,
                             t(:lasgn, :e1, t(:gvar, :$!, Type.unknown),
                               Type.unknown),
                             t(:lit, 2, Type.long), Type.unknown),
                           t(:resbody,
                             t(:array, t(:const, :Exception, Type.fucked)),
                             t(:block,
                               t(:lasgn, :e2, t(:gvar, :$!, Type.unknown),
                                 Type.unknown),
                               t(:lit, 3, Type.long), Type.unknown),
                             Type.unknown), Type.long),
                         t(:lit, 4, Type.long), Type.long),
                       t(:lit, 5, Type.long))), Type.unknown),
                 Type.void),
               Type.function(Type.unknown, [], Type.void))

  @@__all = s()

  @@__type_checker = TypeChecker.new
  @@__type_checker.genv.add :SyntaxError, Type.fucked
  @@__type_checker.genv.add :Exception, Type.fucked
  
  @@__skip = [ "accessor", "accessor=" ]

  Something.instance_methods(false).sort.each do |meth|
    next if @@__skip.include? meth                     
    if class_variables.include?("@@#{meth}") then
      @@__all << eval("@@#{meth}")
      eval "def test_#{meth}
        exp = @@__type_checker.translate Something, :#{meth}
        assert_equal @@#{meth}, exp
      end"
    else
      eval "def test_#{meth}; flunk \"You haven't added @@#{meth} yet\"; end"
    end
  end

  def disabled_test__zzz
    @@__type_checker.functions.each do |name, type|
      puts "#{name}: #{type.inspect}"
    end
  end

end

