#!/usr/local/bin/ruby -w

require 'test/unit'
require 'type_checker'
require 'something'

# Test::Unit::Assertions.use_pp = false

class TestTypeChecker < Test::Unit::TestCase

  def setup
    @type_checker = TypeChecker.new
  end

  def test_and
    input  = s(:and, s(:true), s(:false))
    output = s(:and, s(:true, Type.bool), s(:false, Type.bool), Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_bootstrap
    # bootstrap is automatically called by initialize
    # TODO should we check for EVERYTHING we expect?

    assert_equal Type.file, @type_checker.genv.lookup("$stderr")
    assert_equal Type.file, @type_checker.genv.lookup("$stdout")
    assert_equal Type.file, @type_checker.genv.lookup("$stdin")

    assert_equal(Type.function(Type.long, [Type.long], Type.bool),
                 @type_checker.functions[">"])
  end

  def test_functions
    # bootstrap populates functions
    assert @type_checker.functions.has_key?("puts")
    assert_equal(Type.function(Type.long, [Type.long], Type.bool),
                 @type_checker.functions[">"])
  end

  def test_env
    @type_checker.env.add "blah", Type.long
    assert_equal Type.long, @type_checker.env.lookup("blah") 
 end

  def test_genv
    assert_equal Type.file, @type_checker.genv.lookup("$stderr")
  end

  def test_translate
    result = @type_checker.translate(Something, :empty)
    expect = s(:defn,
               "empty",
               s(:args),
               s(:scope, Type.void),
               Type.function(Type.unknown, [], Type.void))
    assert_equal(expect, result)
  end

  def test_process_args
    @type_checker.env.extend

    input =  s(:args, "foo", "bar")
    output = s(:args,
               s("foo", Type.unknown),
               s("bar", Type.unknown))

    assert_equal output, @type_checker.process(input)
  end

  def test_process_args_empty
    input =  s(:args)
    output = s(:args)
    # TODO: this should be superseded by the new array functionality

    assert_equal output, @type_checker.process(input)
  end

  def test_process_array_single
    add_fake_var "arg1", Type.long

    input  = s(:array, s(:lvar, "arg1"))
    output = s(:array, s(:lvar, "arg1", Type.long))

    result = @type_checker.process(input)

    assert_equal Type.homo, result.sexp_type    
    assert_equal [ Type.long ], result.sexp_types
    assert_equal output, result
  end

  def test_process_array_multiple
    add_fake_var "arg1", Type.long
    add_fake_var "arg2", Type.str

    input =  s(:array, s(:lvar, "arg1"), s(:lvar, "arg2"))
    output = s(:array,
               s(:lvar, "arg1", Type.long),
               s(:lvar, "arg2", Type.str))

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_defined
    add_fake_function "name", Type.void, Type.long, Type.str
    input  = s(:call,
               nil,
               "name",
               s(:array, s(:str, "foo")))
    output = s(:call,
               nil,
               "name",
               s(:array, s(:str, "foo", Type.str)),
               Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_defined_rhs
    add_fake_function "name3", Type.long, Type.long, Type.str
    input  = s(:call,
               s(:lit, 1),
               "name3",
               s(:array, s(:str, "foo")))
    output = s(:call,
               s(:lit, 1, Type.long),
               "name3",
               s(:array, s(:str, "foo", Type.str)),
               Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_undefined
    input  = s(:call, nil, "name", nil)
    output = s(:call, nil, "name", nil, Type.unknown)

    assert_equal output, @type_checker.process(input)
    # FIX returns unknown in s()
    assert_equal(Type.function(Type.unknown, [], Type.unknown),
                 @type_checker.functions["name"])
  end

  def test_process_call_unify_1
    add_fake_var "number", Type.long
    input  = s(:call,
               s(:lit, 1),
               "==",
               s(:array,
                 s(:lvar, "number")))
    output = s(:call,
               s(:lit, 1, Type.long),
               "==",
               s(:array,
                 s(:lvar, "number", Type.long)),
               Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_unify_2
    add_fake_var "number1", Type.unknown
    add_fake_var "number2", Type.unknown

    input  = s(:call,
               s(:lit, 1),
               "==",
               s(:array, s(:lvar, "number1")))
    output = s(:call,
               s(:lit, 1, Type.long),
               "==",
               s(:array,
                 s(:lvar, "number1", Type.long)),
               Type.bool)

    assert_equal output, @type_checker.process(input)

    input  = s(:call,
               s(:lvar, "number2"),
               "==",
               s(:array, s(:lit, 1)))
    output = s(:call,
               s(:lvar, "number2", Type.long),
               "==",
               s(:array,
                 s(:lit, 1, Type.long)),
               Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_case_equal_long
    add_fake_var "number", Type.unknown

    input  = s(:call,
               s(:lit, 1),
               "===",
               s(:array, s(:lvar, "number")))
    output = s(:call,
               s(:lit, 1, Type.long),
               "case_equal_long",
               s(:array,
                 s(:lvar, "number", Type.long)),
               Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_call_case_equal_string
    add_fake_var "string", Type.unknown

    input  = s(:call,
               s(:str, 'foo'),
               "===",
               s(:array, s(:lvar, "string")))
    output = s(:call,
               s(:str, 'foo', Type.str),
               "case_equal_str",
               s(:array,
                 s(:lvar, "string", Type.str)),
               Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_const
    raise NotImplementedError, 'Need to write test_process_const'
  end

  def test_process_block
    add_fake_function Type.unknown, "foo" # TODO: why is this here?

    input  = s(:block, s(:return, s(:nil)))
    # FIX: should this really be void for return?
    output = s(:block,
               s(:return,
                 s(:nil, Type.value),
                 Type.void),
               Type.unknown)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_block_multiple
    add_fake_function Type.unknown, "foo" # what is this really testing?

    input  = s(:block,
               s(:str, "foo"),
               s(:return, s(:nil)))
    output = s(:block,
               s(:str, "foo", Type.str),
               s(:return,
                 s(:nil, Type.value),
                 Type.void),
               Type.unknown)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_dasgn_curr
    @type_checker.env.extend
    input  = s(:dasgn_curr, "x")
    output = s(:dasgn_curr, "x", Type.unknown)

    assert_equal output, @type_checker.process(input)
    # HACK: is this a valid test??? it was in ruby_to_c:
    # assert_equal Type.long, @type_checker.env.lookup("x")
  end

  def test_process_defn
    function_type = Type.function s(), Type.void
    input  = s(:defn,
               "empty",
               s(:args),
               s(:scope))
    output = s(:defn,
               "empty",
               s(:args),
               s(:scope, Type.void),
               function_type)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_dstr
    add_fake_var "var", Type.str
    input  = s(:dstr,
               "var is ",
               s(:lvar, "var"),
               s(:str, ". So there."))
    output = s(:dstr, "var is ",
               s(:lvar, "var", Type.str),
               s(:str, ". So there.", Type.str),
               Type.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_dvar
    add_fake_var "dvar", Type.long
    input  = s(:dvar, "dvar")
    output = s(:dvar, "dvar", Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_false
    input =   s(:false)
    output = s(:false, Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_gvar_defined
    add_fake_gvar "$arg", Type.long
    input  = s(:gvar, "$arg")
    output = s(:gvar, "$arg", Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_gvar_undefined
    input  = s(:gvar, "$arg")
    output = s(:gvar, "$arg", Type.unknown)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_if
    input  = s(:if,
               s(:call,
                 s(:lit, 1),
                 "==",
                 s(:array, s(:lit, 2))),
               s(:str, "not equal"),
               nil)
    output = s(:if,
               s(:call,
                 s(:lit, 1, Type.long),
                 "==",
                 s(:array,
                   s(:lit, 2, Type.long)),
                 Type.bool),
               s(:str, "not equal", Type.str),
               nil,
               Type.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_if_else
    input  = s(:if,
               s(:call,
                 s(:lit, 1),
                 "==",
                 s(:array, s(:lit, 2))),
               s(:str, "not equal"),
               s(:str, "equal"))
    output = s(:if,
               s(:call,
                 s(:lit, 1, Type.long),
                 "==",
                 s(:array, s(:lit, 2, Type.long)),
                 Type.bool),
               s(:str, "not equal", Type.str),
               s(:str, "equal", Type.str),
               Type.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_iter
    @type_checker.env.extend
    var_type = Type.long_list
    add_fake_var "array", var_type
    input  = s(:iter,
               s(:call,
                 s(:lvar, "array"),
                 "each",
                 nil),
               s(:dasgn_curr, "x"),
               s(:call,
                 nil,
                 "puts",
                 s(:array,
                   s(:call,
                     s(:dvar, "x"),
                     "to_s",
                     nil))))
    output = s(:iter,
               s(:call,
                 s(:lvar, "array", var_type),
                 "each",
                 nil,
                 Type.unknown),
               s(:dasgn_curr, "x", Type.long),
               s(:call,
                 nil,
                 "puts",
                 s(:array,
                   s(:call,
                     s(:dvar, "x", Type.long),
                     "to_s",
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
    # s = s(:lasgn, "var", s(:str, "foo"))
    # tc.process(s)
    # => raises
    # tc.env.extend
    # tc.process(s)
    # => raises elsewhere... etc etc etc
    # makes debugging very difficult
    input  = s(:lasgn, "var", s(:str, "foo"))
    output = s(:lasgn, "var", 
               s(:str, "foo", Type.str),
               Type.str)

    assert_equal output, @type_checker.process(input)
  end
  
  def test_process_lasgn_array
    @type_checker.env.extend
    input  = s(:lasgn,
               "var",
               s(:array,
                 s(:str, "foo"),
                 s(:str, "bar")))
    output = s(:lasgn, "var",
               s(:array,
                 s(:str, "foo", Type.str),
                 s(:str, "bar", Type.str)),
               Type.str_list)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_lit
    input  = s(:lit, 1)
    output = s(:lit, 1, Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_lvar
    add_fake_var "arg", Type.long
    input  = s(:lvar, "arg")
    output = s(:lvar, "arg", Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_nil
    input  = s(:nil)
    output = s(:nil, Type.value)

    assert_equal output, @type_checker.process(input)
  end

  def test_or
    input  = s(:or, s(:true), s(:false))
    output = s(:or, s(:true, Type.bool), s(:false, Type.bool), Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_or
    raise NotImplementedError, 'Need to write test_process_or'
  end

  def test_process_rescue
    raise NotImplementedError, 'Need to write test_process_rescue'
  end

  def test_process_return
    input  = s(:return, s(:nil))
    output = s(:return, s(:nil, Type.value), Type.void)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_str
    input  = s(:str, "foo")
    output = s(:str, "foo", Type.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_scope
    add_fake_function Type.unknown, "foo" # TODO: what is this here for?
    input  = s(:scope,
               s(:block,
                 s(:return, s(:nil))))
    output = s(:scope,
               s(:block,
                 s(:return,
                   s(:nil, Type.value),
                   Type.void),
                 Type.unknown), # FIX ? do we care about block?
               Type.void)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_scope_empty
    input =   s(:scope)
    output = s(:scope, Type.void)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_true
    input =  s(:true)
    output = s(:true, Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_unless
    input  = s(:if,
               s(:call,
                 s(:lit, 1),
                 "==",
                 s(:array, s(:lit, 2))),
               nil,
               s(:str, "equal"))
    output = s(:if,
               s(:call,
                 s(:lit, 1, Type.long),
                 "==", 
                 s(:array,
                   s(:lit, 2, Type.long)),
                 Type.bool),
               nil,
               s(:str, "equal", Type.str),
               Type.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_process_while
    raise NotImplementedError, 'Need to write test_process_while'
  end

  def add_fake_function(name, reciever_type = nil, return_type = Type.unknown, *arg_types)
    if reciever_type.nil? then
      $stderr.puts "\nWARNING: reciever_type not specified from #{caller[0]}"
      reciever_type = Type.unknown
    end
    # HACK!!! what is this and why is this??? current_function_name must die!
    @type_checker.instance_variable_set "@current_function_name", name
    functions = @type_checker.instance_variable_get "@functions"
    functions.add_function(name, Type.function(reciever_type, arg_types, return_type))
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

  @@empty = s(:defn, "empty",
              s(:args),
              s(:scope, Type.void),
              Type.function(Type.unknown, [], Type.void))

  @@stupid = s(:defn, "stupid",
               s(:args),
               s(:scope,
                 s(:block,
                   s(:return,
                     s(:nil, Type.value),
                     Type.void),
                   Type.unknown),
                 Type.void),
               Type.function(Type.unknown, [], Type.value))

  @@simple = s(:defn, "simple",
               s(:args, s("arg1", Type.str)),
               s(:scope,
                 s(:block,
                   s(:call,
                     nil,
                     "print",
                     s(:array,
                       s(:lvar,
                         "arg1",
                         Type.str)),
                     Type.void),
                   s(:call,
                     nil,
                     "puts",
                     s(:array,
                       s(:call,
                         s(:call,
                           s(:lit, 4, Type.long),
                           "+",
                           s(:array,
                             s(:lit, 2, Type.long)),
                           Type.long),
                         "to_s",
                         nil, Type.str)),
                     Type.void),
                   Type.unknown),
                 Type.void),
               Type.function(Type.unknown, [Type.str], Type.void)) # HACK - receiver shouldn't be unknown

  @@global = s(:defn, "global",
               s(:args),
               s(:scope,
                 s(:block,
                   s(:call,
                     s(:gvar, "$stderr", Type.file),
                     "fputs",
                     s(:array,
                       s(:str, "blah", Type.str)),
                     Type.unknown),
                   Type.unknown),
                 Type.void),
               Type.function(Type.unknown, [], Type.void))

  @@lasgn_call = s(:defn, "lasgn_call",
                   s(:args),
                   s(:scope,
                     s(:block,
                       s(:lasgn, "c",
                         s(:call,
                           s(:lit, 2, Type.long),
                           "+",
                           s(:array,
                             s(:lit, 3, Type.long)),
                           Type.long),
                         Type.long),
                       Type.unknown),
                     Type.void),
                   Type.function(Type.unknown, [], Type.void))

  @@conditional1 = 
    s(:defn, "conditional1",
      s(:args, s("arg1", Type.long)),
      s(:scope,
        s(:block,
          s(:if,
            s(:call,
              s(:lvar, "arg1", Type.long),
              "==",
              s(:array,
                s(:lit, 0, Type.long)),
              Type.bool),
            s(:return,
              s(:lit, 1, Type.long),
              Type.void),
            nil, Type.void), Type.unknown), Type.void),
      Type.function(Type.unknown, [Type.long], Type.long))

  @@conditional2 = s(:defn, "conditional2",
                     s(:args, s("arg1", Type.long)),
                     s(:scope,
                       s(:block,
                         s(:if,
                           s(:call,
                             s(:lvar, "arg1", Type.long),
                             "==",
                             s(:array,
                               s(:lit, 0, Type.long)),
                             Type.bool),
                           nil,
                           s(:return,
                             s(:lit, 2, Type.long),
                             Type.void),
                           Type.void),
                         Type.unknown),
                       Type.void),
                     Type.function(Type.unknown, [Type.long], Type.long))

  @@conditional3 = s(:defn, "conditional3",
                     s(:args, s("arg1", Type.long)),
                     s(:scope,
                       s(:block,
                         s(:if,
                           s(:call,
                             s(:lvar, "arg1", Type.long),
                             "==",
                             s(:array,
                               s(:lit, 0, Type.long)),
                             Type.bool),
                           s(:return,
                             s(:lit, 3, Type.long),
                             Type.void),
                           s(:return,
                             s(:lit, 4, Type.long),
                             Type.void),
                           Type.void),
                         Type.unknown),
                       Type.void),
                     Type.function(Type.unknown, [Type.long], Type.long))

  @@conditional4 = s(:defn, "conditional4",
                     s(:args, s("arg1", Type.long)),
                     s(:scope,
                       s(:block,
                         s(:if,
                           s(:call,
                             s(:lvar, "arg1", Type.long),
                             "==",
                             s(:array,
                               s(:lit, 0, Type.long)),
                             Type.bool),
                           s(:return,
                             s(:lit, 2, Type.long),
                             Type.void),
                           s(:if,
                             s(:call,
                               s(:lvar, "arg1", Type.long),
                               "<",
                               s(:array,
                                 s(:lit, 0, Type.long)),
                               Type.bool),
                             s(:return,
                               s(:lit, 3, Type.long),
                               Type.void),
                             s(:return,
                               s(:lit, 4, Type.long),
                               Type.void),
                             Type.void),
                           Type.void),
                         Type.unknown),
                       Type.void),
                     Type.function(Type.unknown, [Type.long], Type.long))

  @@__iteration_body = [
    s(:args),
    s(:scope,
      s(:block,
        s(:lasgn, "array",
          s(:array,
            s(:lit, 1, Type.long),
            s(:lit, 2, Type.long),
            s(:lit, 3, Type.long)),
          Type.long_list),
        s(:iter,
          s(:call,
            s(:lvar, "array", Type.long_list),
            "each",
            nil, Type.unknown),
          s(:dasgn_curr, "x", Type.long),
          s(:call,
            nil,
            "puts",
            s(:array,
              s(:call,
                s(:dvar, "x", Type.long),
                "to_s",
                nil,
                Type.str)),
            Type.void),
          Type.void),
        Type.unknown),
      Type.void),
    Type.function(Type.unknown, [], Type.void)]

  @@iteration1 = s(:defn, "iteration1", *@@__iteration_body)

  @@iteration2 = s(:defn, "iteration2", *@@__iteration_body)

  @@iteration3 = s(:defn, "iteration3",
                   s(:args),
                   s(:scope,
                     s(:block,
                       s(:lasgn, "array1",
                         s(:array,
                           s(:lit, 1, Type.long),
                           s(:lit, 2, Type.long),
                           s(:lit, 3, Type.long)),
                         Type.long_list),
                       s(:lasgn, "array2",
                         s(:array,
                           s(:lit, 4, Type.long),
                           s(:lit, 5, Type.long),
                           s(:lit, 6, Type.long),
                           s(:lit, 7, Type.long)),
                         Type.long_list),
                       s(:iter,
                         s(:call,
                           s(:lvar, "array1", Type.long_list),
                           "each",
                           nil,
                           Type.unknown),
                         s(:dasgn_curr, "x", Type.long),
                         s(:iter,
                           s(:call,
                             s(:lvar, "array2", Type.long_list),
                             "each",
                             nil,
                             Type.unknown),
                           s(:dasgn_curr, "y", Type.long),
                           s(:block,
                             s(:call,
                               nil,
                               "puts",
                               s(:array,
                                 s(:call,
                                   s(:dvar, "x", Type.long),
                                   "to_s",
                                   nil,
                                   Type.str)),
                               Type.void),
                             s(:call,
                               nil,
                               "puts",
                               s(:array,
                                 s(:call,
                                   s(:dvar, "y", Type.long),
                                   "to_s",
                                   nil,
                                   Type.str)),
                               Type.void),
                             Type.unknown),
                           Type.void),
                         Type.void),
                       Type.unknown),
                     Type.void),
                   Type.function(Type.unknown, [], Type.void))

  @@iteration4 = s(:defn,
                   "iteration4",
                   s(:args),
                   s(:scope,
                     s(:block,
                       s(:lasgn, "n", s(:lit, 1, Type.long), Type.long),
                       s(:while,
                         s(:call,
                           s(:lvar, "n", Type.long),
                           "<=",
                           s(:array, s(:lit, 3, Type.long)), Type.bool),
                         s(:block,
                           s(:call,
                             nil,
                             "puts",
                             s(:array,
                               s(:call,
                                 s(:lvar, "n", Type.long),
                                 "to_s",
                                 nil, Type.str)), Type.void),
                           s(:lasgn,
                             "n",
                             s(:call,
                               s(:lvar, "n", Type.long),
                               "+",
                               s(:array,
                                 s(:lit,
                                   1, Type.long)), Type.long), Type.long), Type.unknown)), Type.unknown), Type.void),
                   Type.function(Type.unknown, [], Type.void))
  @@iteration5 = s(:defn,
                   "iteration5",
                   s(:args),
                   s(:scope,
                     s(:block,
                       s(:lasgn, "n", s(:lit, 3, Type.long), Type.long),
                       s(:while,
                         s(:call,
                           s(:lvar, "n", Type.long),
                           ">=",
                           s(:array, s(:lit, 1, Type.long)), Type.bool),
                         s(:block,
                           s(:call,
                             nil,
                             "puts",
                             s(:array,
                               s(:call,
                                 s(:lvar, "n", Type.long),
                                 "to_s",
                                 nil, Type.str)), Type.void),
                           s(:lasgn,
                             "n",
                             s(:call,
                               s(:lvar, "n", Type.long),
                               "-",
                               s(:array,
                                 s(:lit,
                                   1, Type.long)),
                               Type.long),
                             Type.long),
                           Type.unknown)),
                       Type.unknown),
                     Type.void),
                   Type.function(Type.unknown, [], Type.void))
  @@multi_args = s(:defn, "multi_args",
                   s(:args,
                     s("arg1", Type.long),
                     s("arg2", Type.long)),
                   s(:scope,
                     s(:block,
                       s(:lasgn,
                         "arg3",
                         s(:call,
                           s(:call,
                             s(:lvar, "arg1", Type.long),
                             "*",
                             s(:array,
                               s(:lvar,
                                 "arg2",
                                 Type.long)),
                             Type.long),
                           "*",
                           s(:array,
                             s(:lit, 7, Type.long)),
                           Type.long),
                         Type.long),
                       s(:call,
                         nil,
                         "puts",
                         s(:array,
                           s(:call,
                             s(:lvar, "arg3", Type.long),
                             "to_s",
                             nil,
                             Type.str)),
                         Type.void),
                       s(:return, s(:str, "foo", Type.str),
                         Type.void),
                       Type.unknown),
                     Type.void),
                   Type.function(Type.unknown, [Type.long, Type.long], Type.str))

  # TODO: why does return false have type void?
  @@bools = s(:defn, "bools",
              s(:args, s("arg1", Type.value)),
              s(:scope,
                s(:block,
                  s(:if,
                    s(:call,
                      s(:lvar, "arg1", Type.value),
                      "nil?",
                      nil,
                      Type.bool),
                    s(:return,
                      s(:false, Type.bool),
                      Type.void),
                    s(:return,
                      s(:true, Type.bool),
                      Type.void),
                    Type.void),
                  Type.unknown),
                Type.void),
              Type.function(Type.unknown, [Type.value], Type.bool))

  @@case_stmt = s(:defn, "case_stmt",
                  s(:args),
                  s(:scope,
                    s(:block,
                      s(:lasgn,
                        "var",
                        s(:lit, 2, Type.long),
                        Type.long),
                      s(:lasgn,
                        "result",
                        s(:str, "", Type.str),
                        Type.str),
                      s(:if,
                        s(:call,
                          s(:lvar, "var", Type.long),
                          "case_equal_long",
                          s(:array, s(:lit, 1, Type.long)),
                          Type.bool),
                        s(:block,
                          s(:call,
                            nil,
                            "puts",
                            s(:array,
                              s(:str, "something", Type.str)),
                            Type.void),
                          s(:lasgn,
                            "result",
                            s(:str, "red", Type.str),
                            Type.str),
                          Type.str),
                        s(:if,
                          s(:or,
                            s(:call,
                              s(:lvar, "var", Type.long),
                              "case_equal_long",
                              s(:array, s(:lit, 2, Type.long)),
                              Type.bool),
                            s(:call,
                              s(:lvar, "var", Type.long),
                              "case_equal_long",
                              s(:array, s(:lit, 3, Type.long)),
                              Type.bool),
                            Type.bool),
                          s(:lasgn,
                            "result",
                            s(:str, "yellow", Type.str),
                            Type.str),
                          s(:if,
                            s(:call,
                              s(:lvar, "var", Type.long),
                              "case_equal_long",
                              s(:array, s(:lit, 4, Type.long)),
                              Type.bool),
                            nil,
                            s(:lasgn,
                              "result",
                              s(:str, "green", Type.str),
                              Type.str),
                            Type.str),
                          Type.str),
                        Type.str),
                      s(:if,
                        s(:call,
                          s(:lvar, "result", Type.str),
                          "case_equal_str",
                          s(:array, s(:str, "red", Type.str)),
                          Type.bool),
                        s(:lasgn, "var", s(:lit, 1, Type.long), Type.long),
                        s(:if,
                          s(:call,
                            s(:lvar, "result", Type.str),
                            "case_equal_str",
                            s(:array, s(:str, "yellow", Type.str)),
                            Type.bool),
                          s(:lasgn, "var", s(:lit, 2, Type.long), Type.long),
                          s(:if,
                            s(:call,
                              s(:lvar, "result", Type.str),
                              "case_equal_str",
                              s(:array,
                                s(:str, "green", Type.str)),
                              Type.bool),
                            s(:lasgn,
                              "var",
                              s(:lit, 3, Type.long),
                              Type.long),
                            nil,
                            Type.long),
                          Type.long),
                        Type.long),
                      s(:return,
                        s(:lvar, "result", Type.str),
                        Type.void),
                      Type.unknown),
                    Type.void),
                  Type.function(Type.unknown, [], Type.str))

  @@eric_is_stubborn = s(:defn,
                         "eric_is_stubborn",
                         s(:args),
                         s(:scope,
                           s(:block,
                             s(:lasgn,
                               "var",
                               s(:lit,
                                 42,
                                 Type.long),
                               Type.long),
                             s(:lasgn,
                               "var2",
                               s(:call,
                                 s(:lvar, "var", Type.long),
                                 "to_s",
                                 nil,
                                 Type.str),
                               Type.str),
                             s(:call,
                               s(:gvar,
                                 "$stderr",
                                 Type.file),
                               "fputs",
                               s(:array,
                                 s(:lvar, "var2", Type.str)),
                               Type.unknown),
                             s(:return,
                               s(:lvar, "var2", Type.str),
                               Type.void),
                             Type.unknown),
                           Type.void),
                         Type.function(Type.unknown, [], Type.str))

  @@interpolated = s(:defn,
                     "interpolated",
                     s(:args),
                     s(:scope,
                       s(:block,
                         s(:lasgn,
                           "var",
                           s(:lit,
                             14,
                             Type.long),
                           Type.long),
                         s(:lasgn, "var2",
                           s(:dstr,
                             "var is ",
                             s(:lvar, "var", Type.long),
                             s(:str, ". So there.", Type.str),
                             Type.str),
                           Type.str),
                         Type.unknown),
                       Type.void),
                     Type.function(Type.unknown, [], Type.void))

  @@unknown_args = s(:defn, "unknown_args",
                     s(:args,
                       s("arg1", Type.long),
                       s("arg2", Type.str)),
                     s(:scope,
                       s(:block,
                         s(:return,
                           s(:lvar,
                             "arg1",
                             Type.long),
                           Type.void),
                         Type.unknown),
                       Type.void),
                     Type.function(Type.unknown, [Type.long, Type.str], Type.long))

  @@determine_args = s(:defn, "determine_args",
                       s(:args),
                       s(:scope,
                         s(:block,
                           s(:call,
                             s(:lit,
                               5,
                               Type.long),
                             "==",
                             s(:array,
                               s(:call,
                                 nil,
                                 "unknown_args",
                                 s(:array,
                                   s(:lit, 4, Type.long),
                                   s(:str, "known", Type.str)),
                                 Type.long)),
                             Type.bool),
                           Type.unknown),
                         Type.void),
                       Type.function(Type.unknown, [], Type.void))

  @@__all = s()

  @@__type_checker = TypeChecker.new

  Something.instance_methods(false).sort.each do |meth|
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

