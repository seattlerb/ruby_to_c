#!/usr/local/bin/ruby -w

$TESTING = true

require 'minitest/autorun' if $0 == __FILE__
require 'type_checker'
require 'r2ctestcase'

class DumbClass # ZenTest SKIP
  def empty
  end
end

class X # ZenTest SKIP
  VALUE = 42
end

class TestTypeChecker < R2CTestCase
  def setup
    @type_checker = TypeChecker.new
    @processor = @type_checker
    @type_checker.env.add :argl, CType.long
    @type_checker.env.add :args, CType.str
    @type_checker.env.add :arrayl, CType.long_list
    @type_checker.env.add :arrayl2, CType.long_list
    @type_checker.env.add :arrays, CType.str_list
    @type_checker.genv.add :SyntaxError, CType.fucked
    @type_checker.genv.add :Exception, CType.fucked

    # HACK
    @type_checker.genv.add :$stdin, CType.file
    @type_checker.genv.add :$stdout, CType.file
    @type_checker.genv.add :$stderr, CType.file
  end

  def test_bootstrap
    # bootstrap is automatically called by initialize
    # TODO should we check for EVERYTHING we expect?

# HACK
#     assert_equal CType.file, @type_checker.genv.lookup(:$stdin)
#     assert_equal CType.file, @type_checker.genv.lookup(:$stdout)
#     assert_equal CType.file, @type_checker.genv.lookup(:$stderr)

    assert_equal(CType.function(CType.long, [CType.long], CType.bool),
                 @type_checker.functions[:>])
  end

  def test_defn_call_unify
    # pre-registered function, presumibly through another :call elsewhere
    add_fake_function :specific, CType.unknown, CType.unknown, CType.unknown

    # now in specific, unify with a long
    _ = @type_checker.process(s(:defn, :specific,
                                s(:args, :x),
                                s(:scope,
                                  s(:block,
                                    s(:lasgn, :x, s(:lit, 2))))))
    s_type = @type_checker.functions[:specific]

    assert_equal(CType.long,
                 s_type.list_type.formal_types[0])
# HACK    flunk "eric hasn't finished writing me yet. guilt. guilt. guilt."
  end

  def test_env
    @type_checker.env.add :blah, CType.long
    assert_equal CType.long, @type_checker.env.lookup(:blah)
  end

  def test_functions
    # bootstrap populates functions
    assert @type_checker.functions.has_key?(:puts)
    assert_equal(CType.function(CType.long, [CType.long], CType.bool),
                 @type_checker.functions[:>])
  end

# HACK
#   def test_genv
#     assert_equal CType.file, @type_checker.genv.lookup(:$stderr)
#   end

  def test_process_args
    @type_checker.env.extend

    input =  t(:args, :foo, :bar)
    output = t(:args,
               t(:foo, CType.unknown),
               t(:bar, CType.unknown))

    assert_equal output, @type_checker.process(input)
  end

  def test_process_args_empty
    input =  t(:args)
    output = t(:args)
    # TODO: this should be superseded by the new array functionality

    assert_equal output, @type_checker.process(input)
  end

  def test_process_array_multiple
    add_fake_var :arg1, CType.long
    add_fake_var :arg2, CType.str

    input =  t(:array, t(:lvar, :arg1), t(:lvar, :arg2))
    output = t(:array,
               t(:lvar, :arg1, CType.long),
               t(:lvar, :arg2, CType.str))

    assert_equal output, @type_checker.process(input)
  end

  def test_process_array_single
    add_fake_var :arg1, CType.long

    input  = t(:array, t(:lvar, :arg1))
    output = t(:array, t(:lvar, :arg1, CType.long))

    result = @type_checker.process(input)

    assert_equal CType.homo, result.c_type
    assert_equal [ CType.long ], result.c_types
    assert_equal output, result
  end

  def test_process_block
    input  = t(:block, t(:return, t(:nil)))
    # FIX: should this really be void for return?
    output = t(:block,
               t(:return,
                 t(:nil, CType.value),
                 CType.void),
               CType.unknown)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_block_multiple
    input  = t(:block,
               t(:str, :foo),
               t(:return, t(:nil)))
    output = t(:block,
               t(:str, :foo, CType.str),
               t(:return,
                 t(:nil, CType.value),
                 CType.void),
               CType.unknown)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_case_equal_long
    add_fake_var :number, CType.unknown

    input  = t(:call,
               t(:lit, 1),
               :===,
               t(:arglist, t(:lvar, :number)))
    output = t(:call,
               t(:lit, 1, CType.long),
               :case_equal_long,
               t(:arglist,
                 t(:lvar, :number, CType.long)),
               CType.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_case_equal_string
    add_fake_var :string, CType.unknown

    input  = t(:call,
               t(:str, 'foo'),
               :===,
               t(:arglist, t(:lvar, :string)))
    output = t(:call,
               t(:str, 'foo', CType.str),
               :case_equal_str,
               t(:arglist,
                 t(:lvar, :string, CType.str)),
               CType.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_defined
    add_fake_function :name, CType.void, CType.long, CType.str
    input  = t(:call,
               nil,
               :name,
               t(:arglist, t(:str, "foo")))
    output = t(:call,
               nil,
               :name,
               t(:arglist, t(:str, "foo", CType.str)),
               CType.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_defined_rhs
    add_fake_function :name3, CType.long, CType.long, CType.str
    input  = t(:call,
               t(:lit, 1),
               :name3,
               t(:arglist, t(:str, "foo")))
    output = t(:call,
               t(:lit, 1, CType.long),
               :name3,
               t(:arglist, t(:str, "foo", CType.str)),
               CType.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_undefined
    input  = t(:call, nil, :name)
    output = t(:call, nil, :name, t(:arglist), CType.unknown)

    assert_equal output, @type_checker.process(input)
    # FIX returns unknown in s()
    assert_equal(CType.function(CType.unknown, [], CType.unknown),
                 @type_checker.functions[:name])
  end

  def test_process_call_unify_1
    add_fake_var :number, CType.long
    input  = t(:call,
               t(:lit, 1),
               :==,
               t(:arglist,
                 t(:lvar, :number)))
    output = t(:call,
               t(:lit, 1, CType.long),
               :==,
               t(:arglist,
                 t(:lvar, :number, CType.long)),
               CType.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_unify_2
    add_fake_var :number1, CType.unknown
    add_fake_var :number2, CType.unknown

    input  = t(:call,
               t(:lit, 1),
               :==,
               t(:arglist, t(:lvar, :number1)))
    output = t(:call,
               t(:lit, 1, CType.long),
               :==,
               t(:arglist,
                 t(:lvar, :number1, CType.long)),
               CType.bool)

    assert_equal output, @type_checker.process(input)

    input  = t(:call,
               t(:lvar, :number2),
               :==,
               t(:arglist, t(:lit, 1)))
    output = t(:call,
               t(:lvar, :number2, CType.long),
               :==,
               t(:arglist,
                 t(:lit, 1, CType.long)),
               CType.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_unify_3
    a_type = CType.unknown
    add_fake_var :a, a_type # TODO: CType.unknown

    # def unify_3_outer(a)
    #
    #             unk
    #              ^
    #              |
    # outer(., ., [+])

    # assume the environment got everything set up correctly
    add_fake_function(:unify_3_outer, CType.void, CType.void, a_type)

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
                            t(:arglist, t(:lvar, :a))))

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

    assert_equal a_type, CType.long

    assert_equal(@type_checker.functions[:unify_3_inner].list_type.formal_types[0],
                 @type_checker.functions[:unify_3_outer].list_type.formal_types[0])
  end

  # HACK: putting class X above w/ some consts
  def test_process_class
    input = s(:class, :X, :Object,
              s(:defn, :meth,
                s(:args, :x),
                s(:scope,
                  s(:block,
                    s(:lasgn, :x, s(:const, :VALUE))))))
    output = t(:class, :X, :Object,
               t(:defn, :meth,
                 t(:args, t(:x, CType.long)),
                 t(:scope,
                   t(:block,
                     t(:lasgn, :x,
                       t(:const, :VALUE, CType.long),
                       CType.long),
                     CType.unknown),
                   CType.void),
                 CType.function(CType.unknown, [CType.long], CType.void)),
               CType.zclass)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_const
    assert_raises NameError do
      @type_checker.process s(:const, :NonExistant)
    end
  end

  def test_process_cvar
    input  = s(:cvar, :name)
    output = t(:cvar, :name, CType.unknown)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_cvasgn
    input  = s(:cvasgn, :name, s(:lit, 4))
    output = t(:cvasgn, :name, t(:lit, 4, CType.long), CType.unknown)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_dasgn_curr
    @type_checker.env.extend
    input  = t(:dasgn_curr, :x)
    output = t(:dasgn_curr, :x, CType.unknown)

    assert_equal output, @type_checker.process(input)
    # HACK: is this a valid test??? it was in ruby_to_c:
    # assert_equal CType.long, @type_checker.env.lookup(:x)
  end

  def test_process_defn
    function_type = CType.function s(), CType.void
    input  = t(:defn,
               :empty,
               t(:args),
               t(:scope))
    output = t(:defn,
               :empty,
               t(:args),
               t(:scope, CType.void),
               function_type)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_dstr
    add_fake_var :var, CType.str
    input  = t(:dstr,
               "var is ",
               t(:lvar, :var),
               t(:str, ". So there."))
    output = t(:dstr, "var is ",
               t(:lvar, :var, CType.str),
               t(:str, ". So there.", CType.str),
               CType.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_dvar
    add_fake_var :dvar, CType.long
    input  = t(:dvar, :dvar)
    output = t(:dvar, :dvar, CType.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_false
    input =   t(:false)
    output = t(:false, CType.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_gasgn
    input = s(:gasgn, :$blah, s(:lit, 42))
    expected = t(:gasgn, :$blah, t(:lit, 42, CType.long), CType.long)

    assert_equal expected, @type_checker.process(input)
  end

  def test_process_gvar_defined
    add_fake_gvar :$arg, CType.long
    input  = t(:gvar, :$arg)
    output = t(:gvar, :$arg, CType.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_gvar_undefined
    input  = t(:gvar, :$arg)
    output = t(:gvar, :$arg, CType.unknown)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_iasgn
    input = s(:iasgn, :@blah, s(:lit, 42))
    expected = t(:iasgn, :@blah, t(:lit, 42, CType.long), CType.long)

    assert_equal expected, @type_checker.process(input)
  end

  def test_process_if
    input  = t(:if,
               t(:call,
                 t(:lit, 1),
                 :==,
                 t(:arglist, t(:lit, 2))),
               t(:str, "not equal"),
               nil)
    output = t(:if,
               t(:call,
                 t(:lit, 1, CType.long),
                 :==,
                 t(:arglist,
                   t(:lit, 2, CType.long)),
                 CType.bool),
               t(:str, "not equal", CType.str),
               nil,
               CType.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_if_else
    input  = t(:if,
               t(:call,
                 t(:lit, 1),
                 :==,
                 t(:arglist, t(:lit, 2))),
               t(:str, "not equal"),
               t(:str, "equal"))
    output = t(:if,
               t(:call,
                 t(:lit, 1, CType.long),
                 :==,
                 t(:arglist, t(:lit, 2, CType.long)),
                 CType.bool),
               t(:str, "not equal", CType.str),
               t(:str, "equal", CType.str),
               CType.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_iter
    @type_checker.env.extend
    var_type = CType.long_list
    add_fake_var :array, var_type
    input  = t(:iter,
               t(:call,
                 t(:lvar, :array),
                 :each,
                 nil),
               t(:args, :x),
               t(:call,
                 nil,
                 :puts,
                 t(:arglist,
                   t(:call,
                     t(:dvar, :x),
                     :to_s,
                     nil))))
    output = t(:iter,
               t(:call,
                 t(:lvar, :array, var_type),
                 :each,
                 t(:arglist),
                 CType.unknown),
               t(:args, t(:lasgn, :x, nil, CType.long)),
               t(:call,
                 nil,
                 :puts,
                 t(:arglist,
                   t(:call,
                     t(:dvar, :x, CType.long),
                     :to_s,
                     t(:arglist),
                     CType.str)),
                 CType.void),
               CType.void)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_ivar
    @type_checker.env.add :@blah, CType.long
    input = s(:ivar, :@blah)
    expected = t(:ivar, :@blah, CType.long)

    assert_equal expected, @type_checker.process(input)
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
               t(:str, "foo", CType.str),
               CType.str)

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
                 t(:str, "foo", CType.str),
                 t(:str, "bar", CType.str)),
               CType.str_list)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_lasgn_masgn
    @type_checker.env.extend
    input  = t(:lasgn, :var)
    output = t(:lasgn, :var, nil, CType.unknown)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_lit_float
    input  = t(:lit, 1.0)
    output = t(:lit, 1.0, CType.float)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_lit_long
    input  = t(:lit, 1)
    output = t(:lit, 1, CType.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_lit_sym
    input  = t(:lit, :sym)
    output = t(:lit, :sym, CType.symbol)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_lvar
    add_fake_var :arg, CType.long
    input  = t(:lvar, :arg)
    output = t(:lvar, :arg, CType.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_masgn_equal_args
    input  = s(:masgn,
               s(:array,
                 s(:lasgn, :a),
                 s(:lasgn, :b)),
               s(:array, s(:lit, 1), s(:lit, 2)))
    output = t(:masgn,
               t(:array,
                 t(:lasgn, :a, nil, CType.long),
                 t(:lasgn, :b, nil, CType.long)),
               t(:array,
                 t(:lit, 1, CType.long),
                 t(:lit, 2, CType.long),
                 CType.long_list))

    assert_equal output, @type_checker.process(input)
  end

  def test_process_masgn_less_args
    input  = s(:masgn,
               s(:array,
                 s(:lasgn, :a),
                 s(:lasgn, :b)),
               s(:to_ary, s(:lit, 1)))
    output = t(:masgn,
               t(:array,
                 t(:lasgn, :a, nil, CType.long),
                 t(:lasgn, :b, nil, CType.value)),
               t(:to_ary,
                 t(:lit, 1, CType.long),
                 CType.long_list))

    assert_equal output, @type_checker.process(input)
  end

  def test_process_masgn_more_args
    input  = s(:masgn,
               s(:array,
                 s(:lasgn, :a),
                 s(:lasgn, :b)),
               s(:array, s(:lit, 1), s(:lit, 2), s(:lit, 3)))
    output = t(:masgn,
               t(:array,
                 t(:lasgn, :a, nil, CType.long),
                 t(:lasgn, :b, nil, CType.long_list)),
               t(:array,
                 t(:lit, 1, CType.long),
                 t(:lit, 2, CType.long),
                 t(:lit, 3, CType.long),
                 CType.long_list))

    assert_equal output, @type_checker.process(input)
  end

  def test_process_nil
    input  = t(:nil)
    output = t(:nil, CType.value)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_not
    input  = t(:not, t(:true))
    output = t(:not, t(:true, CType.bool), CType.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_or
    input  = t(:or, t(:true), t(:false))
    output = t(:or, t(:true, CType.bool), t(:false, CType.bool), CType.bool)

    assert_equal output, @type_checker.process(input)
  end

#   def test_process_rescue
#     assert_raises RuntimeError do
#       @type_checker.process s(:rescue, s(:true), s(:true))
#     end
#   end

  def test_process_return
    input  = t(:return, t(:nil))
    output = t(:return, t(:nil, CType.value), CType.void)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_scope
    input  = t(:scope,
               t(:block,
                 t(:return, t(:nil))))
    output = t(:scope,
               t(:block,
                 t(:return,
                   t(:nil, CType.value),
                   CType.void),
                 CType.unknown), # FIX ? do we care about block?
               CType.void)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_scope_empty
    input =   t(:scope)
    output = t(:scope, CType.void)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_str
    input  = t(:str, "foo")
    output = t(:str, "foo", CType.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_to_ary
    input  = s(:to_ary, s(:lit, 1), s(:lit, 2))
    output = t(:to_ary,
               t(:lit, 1, CType.long),
               t(:lit, 2, CType.long),
               CType.long_list)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_true
    input =  t(:true)
    output = t(:true, CType.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_unless
    input  = t(:if,
               t(:call,
                 t(:lit, 1),
                 :==,
                 t(:arglist, t(:lit, 2))),
               nil,
               t(:str, "equal"))
    output = t(:if,
               t(:call,
                 t(:lit, 1, CType.long),
                 :==,
                 t(:arglist,
                   t(:lit, 2, CType.long)),
                 CType.bool),
               nil,
               t(:str, "equal", CType.str),
               CType.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_while
    input    = t(:while, t(:true), t(:call, t(:lit, 1), :to_s, nil), true)
    expected = t(:while,
                 t(:true, CType.bool),
                 t(:call, t(:lit, 1, CType.long), :to_s, t(:arglist),
                   CType.str), true)

    assert_equal expected, @type_checker.process(input)
  end

  def add_fake_function(name, reciever_type, return_type, *arg_types)
    @type_checker.functions.add_function(name,
                                         CType.function(reciever_type, arg_types, return_type))
  end

  def add_fake_var(name, type)
    @type_checker.env.extend
    @type_checker.env.add name, type
  end

  def add_fake_gvar(name, type)
    @type_checker.genv.add name, type
  end
end

