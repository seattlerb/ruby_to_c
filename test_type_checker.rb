#!/usr/local/bin/ruby -w

require 'test/unit'
require 'type_checker'
require 'something'

# Test::Unit::Assertions.use_pp = false

class TestTypeChecker_1 < Test::Unit::TestCase

  def setup
    @type_checker = TypeChecker.new
  end

  def test_args
    @type_checker.env.extend

    input =  Sexp.new(:args, "foo", "bar")
    output = Sexp.new(:args,
                      Sexp.new("foo", Type.unknown),
                      Sexp.new("bar", Type.unknown))

    assert_equal output, @type_checker.process(input)
  end

  def test_args_empty
    input =  Sexp.new(:args)
    output = Sexp.new(:args)
    # TODO: this should be superseded by the new array functionality

    assert_equal output, @type_checker.process(input)
  end

  def test_array_single
    add_fake_var "arg1", Type.long

    input  = Sexp.new(:array, Sexp.new(:lvar, "arg1"))
    output = Sexp.new(:array, Sexp.new(:lvar, "arg1", Type.long))

    result = @type_checker.process(input)

    assert_equal Type.homo, result.sexp_type    
    assert_equal [ Type.long ], result.sexp_types
    assert_equal output, result
  end

  def test_array_multiple
    add_fake_var "arg1", Type.long
    add_fake_var "arg2", Type.str

    input =  Sexp.new(:array, Sexp.new(:lvar, "arg1"), Sexp.new(:lvar, "arg2"))
    output = Sexp.new(:array,
                      Sexp.new(:lvar, "arg1", Type.long),
                      Sexp.new(:lvar, "arg2", Type.str))

    assert_equal output, @type_checker.process(input)
  end

  def test_call_defined
    add_fake_function "name", Type.long, Type.str
    input  = Sexp.new(:call,
                       "name",
                       nil,
                       Sexp.new(:array, Sexp.new(:str, "foo")))
    output = Sexp.new(:call,
                      "name",
                      nil,
                      Sexp.new(:array, Sexp.new(:str, "foo", Type.str)),
                      Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_call_defined_rhs
    add_fake_function "name", Type.long, Type.long, Type.str
    input  = Sexp.new(:call,
                      "name",
                      Sexp.new(:lit, 1),
                      Sexp.new(:array, Sexp.new(:str, "foo")))
    output = Sexp.new(:call,
                      "name",
                      Sexp.new(:lit, 1, Type.long),
                      Sexp.new(:array,
                               Sexp.new(:str, "foo", Type.str)), Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_call_undefined
    input  = Sexp.new(:call, "name", nil, nil)
    output = Sexp.new(:call, "name", nil, nil, Type.unknown)

    assert_equal output, @type_checker.process(input)
    assert_equal Type.function([], Type.unknown), # FIX returns unknown in Sexp.new()
                 @type_checker.functions["name"]
  end

  def test_call_unify_1
    add_fake_var "number", Type.long
    input  = Sexp.new(:call,
                      "==",
                      Sexp.new(:lit, 1),
                      Sexp.new(:array, Sexp.new(:lvar, "number")))
    output = Sexp.new(:call, "==",
                      Sexp.new(:lit, 1, Type.long),
                      Sexp.new(:array,
                               Sexp.new(:lvar, "number", Type.long)),
                      Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_call_unify_2
    add_fake_var "number1", Type.unknown
    add_fake_var "number2", Type.unknown

    input  = Sexp.new(:call,
                      "==",
                      Sexp.new(:lit, 1),
                      Sexp.new(:array, Sexp.new(:lvar, "number1")))
    output = Sexp.new(:call,
                      "==",
                      Sexp.new(:lit, 1, Type.long),
                      Sexp.new(:array,
                               Sexp.new(:lvar, "number1", Type.long)),
                      Type.bool)

    assert_equal output, @type_checker.process(input)

    input  = Sexp.new(:call,
                      "==",
                      Sexp.new(:lvar, "number2"),
                      Sexp.new(:array, Sexp.new(:lit, 1)))
    output = Sexp.new(:call,
                      "==",
                      Sexp.new(:lvar, "number2", Type.long),
                      Sexp.new(:array,
                               Sexp.new(:lit, 1, Type.long)),
                      Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_call_case_equal
    add_fake_var "number", Type.unknown
    add_fake_var "string", Type.unknown

    input  = Sexp.new(:call,
                      "===",
                      Sexp.new(:lit, 1),
                      Sexp.new(:array, Sexp.new(:lvar, "number")))
    output = Sexp.new(:call,
                      "case_equal_long",
                      Sexp.new(:lit, 1, Type.long),
                      Sexp.new(:array,
                               Sexp.new(:lvar, "number", Type.long)),
                      Type.bool)

    assert_equal output, @type_checker.process(input)

    input  = Sexp.new(:call,
                      "===",
                      Sexp.new(:str, 'foo'),
                      Sexp.new(:array, Sexp.new(:lvar, "string")))
    output = Sexp.new(:call,
                      "case_equal_str",
                      Sexp.new(:str, 'foo', Type.str),
                      Sexp.new(:array,
                               Sexp.new(:lvar, "string", Type.str)),
                      Type.bool)

    assert_equal output, @type_checker.process(input)

  end

  def test_block
    add_fake_function "foo"

    input  = Sexp.new(:block, Sexp.new(:return, Sexp.new(:nil)))
    # FIX: should this really be void for return?
    output = Sexp.new(:block,
                      Sexp.new(:return,
                               Sexp.new(:nil, Type.value),
                               Type.void),
                      Type.unknown)

    assert_equal output, @type_checker.process(input)
  end

  def test_block_multiple
    add_fake_function "foo"

    input  = Sexp.new(:block,
                      Sexp.new(:str, "foo"),
                      Sexp.new(:return, Sexp.new(:nil)))
    output = Sexp.new(:block,
                      Sexp.new(:str, "foo", Type.str),
                      Sexp.new(:return,
                               Sexp.new(:nil, Type.value),
                               Type.void),
                      Type.unknown)

    assert_equal output, @type_checker.process(input)
  end

  def test_dasgn
    @type_checker.env.extend
    input  = Sexp.new(:dasgn_curr, "x")
    output = Sexp.new(:dasgn_curr, "x", Type.unknown)

    assert_equal output, @type_checker.process(input)
    # HACK: is this a valid test??? it was in ruby_to_c:
    # assert_equal Type.long, @type_checker.env.lookup("x")
  end

  def test_defn
    function_type = Type.function Sexp.new(), Type.void
    input  = Sexp.new(:defn,
                      "empty",
                      Sexp.new(:args),
                      Sexp.new(:scope))
    output = Sexp.new(:defn,
                      "empty",
                      Sexp.new(:args),
                      Sexp.new(:scope, Type.void),
                      function_type)

    assert_equal output, @type_checker.process(input)
  end

  def test_dstr
    add_fake_var "var", Type.str
    input  = Sexp.new(:dstr,
                      "var is ",
                      Sexp.new(:lvar, "var"),
                      Sexp.new(:str, ". So there."))
    output = Sexp.new(:dstr, "var is ",
                      Sexp.new(:lvar, "var", Type.str),
                      Sexp.new(:str, ". So there.", Type.str),
                      Type.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_dvar
    add_fake_var "dvar", Type.long
    input  = Sexp.new(:dvar, "dvar")
    output = Sexp.new(:dvar, "dvar", Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_false
    input =   Sexp.new(:false)
    output = Sexp.new(:false, Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_gvar_defined
    add_fake_gvar "$arg", Type.long
    input  = Sexp.new(:gvar, "$arg")
    output = Sexp.new(:gvar, "$arg", Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_gvar_undefined
    input  = Sexp.new(:gvar, "$arg")
    output = Sexp.new(:gvar, "$arg", Type.unknown)

    assert_equal output, @type_checker.process(input)
  end

  def test_if
    input  = Sexp.new(:if,
                      Sexp.new(:call,
                               "==",
                               Sexp.new(:lit, 1),
                               Sexp.new(:array, Sexp.new(:lit, 2))),
                      Sexp.new(:str, "not equal"),
                    nil)
    output = Sexp.new(:if,
                      Sexp.new(:call,
                               "==",
                               Sexp.new(:lit, 1, Type.long),
                               Sexp.new(:array,
                                        Sexp.new(:lit, 2, Type.long)),
                               Type.bool),
                    Sexp.new(:str, "not equal", Type.str),
                    nil,
              Type.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_if_else
    input  = Sexp.new(:if,
                      Sexp.new(:call,
                               "==",
                               Sexp.new(:lit, 1),
                               Sexp.new(:array, Sexp.new(:lit, 2))),
                      Sexp.new(:str, "not equal"),
                      Sexp.new(:str, "equal"))
    output = Sexp.new(:if,
                      Sexp.new(:call,
                               "==",
                               Sexp.new(:lit, 1, Type.long),
                               Sexp.new(:array, Sexp.new(:lit, 2, Type.long)),
                               Type.bool),
                      Sexp.new(:str, "not equal", Type.str),
                      Sexp.new(:str, "equal", Type.str),
                      Type.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_iter
    @type_checker.env.extend
    var_type = Type.long_list
    add_fake_var "array", var_type
    input  = Sexp.new(:iter,
                      Sexp.new(:call,
                               "each",
                               Sexp.new(:lvar, "array"),
                               nil),
                      Sexp.new(:dasgn_curr, "x"),
                      Sexp.new(:call,
                               "puts",
                               nil,
                               Sexp.new(:array,
                                        Sexp.new(:call,
                                                 "to_s",
                                                 Sexp.new(:dvar, "x"), nil))))
    output = Sexp.new(:iter,
                      Sexp.new(:call,
                               "each",
                               Sexp.new(:lvar, "array", var_type),
                               nil,
                               Type.unknown),
                      Sexp.new(:dasgn_curr, "x", Type.long),
                      Sexp.new(:call,
                               "puts",
                               nil,
                               Sexp.new(:array,
                                        Sexp.new(:call,
                                                 "to_s",
                                                 Sexp.new(:dvar,
                                                          "x", Type.long),
                                                 nil,
                                                 Type.str)),
                               Type.void),
                      Type.void)

    assert_equal output, @type_checker.process(input)
  end

  def test_lasgn
    @type_checker.env.extend # FIX: this is a design flaw... examine irb sess:
    # require 'sexp_processor'
    # require 'type_checker'
    # tc = TypeChecker.new
    # s = Sexp.new(:lasgn, "var", Sexp.new(:str, "foo"))
    # tc.process(s)
    # => raises
    # tc.env.extend
    # tc.process(s)
    # => raises elsewhere... etc etc etc
    # makes debugging very difficult
    input  = Sexp.new(:lasgn, "var", Sexp.new(:str, "foo"))
    output = Sexp.new(:lasgn, "var", 
                      Sexp.new(:str, "foo", Type.str),
                      Type.str)

    assert_equal output, @type_checker.process(input)
  end
  
  def test_lasgn_array
    @type_checker.env.extend
    input  = Sexp.new(:lasgn,
                      "var",
                      Sexp.new(:array,
                               Sexp.new(:str, "foo"),
                               Sexp.new(:str, "bar")))
    output = Sexp.new(:lasgn, "var",
                      Sexp.new(:array,
                               Sexp.new(:str, "foo", Type.str),
                               Sexp.new(:str, "bar", Type.str)),
                      Type.str_list)

    assert_equal output, @type_checker.process(input)
  end

  def test_lit
    input  = Sexp.new(:lit, 1)
    output = Sexp.new(:lit, 1, Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_lvar
    add_fake_var "arg", Type.long
    input  = Sexp.new(:lvar, "arg")
    output = Sexp.new(:lvar, "arg", Type.long)

    assert_equal output, @type_checker.process(input)
  end

  def test_nil
    input  = Sexp.new(:nil)
    output = Sexp.new(:nil, Type.value)

    assert_equal output, @type_checker.process(input)
  end

  def test_return
    add_fake_function "foo"

    input  = Sexp.new(:return, Sexp.new(:nil))
    output = Sexp.new(:return, Sexp.new(:nil, Type.value), Type.void)

    x = output

    assert_equal x, @type_checker.process(input)
  end

  def test_return_raises
    input = Sexp.new(:return, Sexp.new(:nil))

    assert_raises RuntimeError do
      @type_checker.process(input)
    end
  end

  def test_str
    input  = Sexp.new(:str, "foo")
    output = Sexp.new(:str, "foo", Type.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_scope
    add_fake_function "foo"
    input  = Sexp.new(:scope,
                      Sexp.new(:block,
                               Sexp.new(:return, Sexp.new(:nil))))
    output = Sexp.new(:scope,
                      Sexp.new(:block,
                               Sexp.new(:return,
                                        Sexp.new(:nil, Type.value),
                                        Type.void),
                               Type.unknown), # FIX ? do we care about block?
                      Type.void)

    assert_equal output, @type_checker.process(input)
  end

  def test_scope_empty
    input =   Sexp.new(:scope)
    output = Sexp.new(:scope, Type.void)

    assert_equal output, @type_checker.process(input)
  end

  def test_true
    input =  Sexp.new(:true)
    output = Sexp.new(:true, Type.bool)

    assert_equal output, @type_checker.process(input)
  end

  def test_unless
    input  = Sexp.new(:if,
                      Sexp.new(:call,
                               "==",
                               Sexp.new(:lit, 1),
                               Sexp.new(:array, Sexp.new(:lit, 2))),
                      nil,
                      Sexp.new(:str, "equal"))
    output = Sexp.new(:if,
                      Sexp.new(:call,
                               "==", 
                               Sexp.new(:lit, 1, Type.long),
                               Sexp.new(:array,
                                        Sexp.new(:lit, 2, Type.long)),
                               Type.bool),
                      nil,
                      Sexp.new(:str, "equal", Type.str),
                      Type.str)

    assert_equal output, @type_checker.process(input)
  end

  def add_fake_function(name, return_type = Type.unknown, *arg_types)
    @type_checker.instance_variable_set "@current_function_name", name
    functions = @type_checker.instance_variable_get "@functions"
    functions[name] = Type.function arg_types, return_type
  end

  def add_fake_var(name, type)
    @type_checker.env.extend
    @type_checker.env.add name, type
  end

  def add_fake_gvar(name, type)
    @type_checker.genv.add name, type
  end

end

class TestTypeChecker_2 < Test::Unit::TestCase

  # TODO: need a good test of interpolated strings

  @@missing = Sexp.new(nil)

  @@empty = Sexp.new(:defn, "empty",
                     Sexp.new(:args),
                     Sexp.new(:scope, Type.void),
                     Type.function([], Type.void))

  @@stupid = Sexp.new(:defn, "stupid",
                      Sexp.new(:args),
                      Sexp.new(:scope,
                               Sexp.new(:block,
                                        Sexp.new(:return,
                                                 Sexp.new(:nil, Type.value),
                                                 Type.void),
                                        Type.unknown),
                               Type.void),
                      Type.function([], Type.value))

  @@simple = Sexp.new(:defn, "simple",
                      Sexp.new(:args, Sexp.new("arg1", Type.str)),
                      Sexp.new(:scope,
                               Sexp.new(:block,
                                        Sexp.new(:call,
                                                 "print",
                                                 nil,
                                                 Sexp.new(:array,
                                                          Sexp.new(:lvar,
                                                                   "arg1",
                                                                   Type.str)),
                                                 Type.void),
                                        Sexp.new(:call,
                                                 "puts",
                                                 nil,
                                                 Sexp.new(:array,
                                                          Sexp.new(:call,
                                                                   "to_s",
                                                                   Sexp.new(:call,
                                                                            "+",
                                                                            Sexp.new(:lit, 4, Type.long),
                                                                            Sexp.new(:array,
                                                                                     Sexp.new(:lit, 2, Type.long)),
                                                                            Type.long),
                                                                   nil, Type.str)),
                                                 Type.void),
                                        Type.unknown),
                               Type.void),
                      Type.function([Type.str], Type.void))

  @@global = Sexp.new(:defn, "global",
                      Sexp.new(:args),
                      Sexp.new(:scope,
                               Sexp.new(:block,
                                        Sexp.new(:call, "fputs",
                                                 Sexp.new(:gvar, "$stderr", Type.file),
                                                 Sexp.new(:array,
                                                          Sexp.new(:str, "blah", Type.str)),
                                                 Type.unknown),
                                        Type.unknown),
                               Type.void),
                      Type.function([], Type.void))

  @@lasgn_call = Sexp.new(:defn, "lasgn_call",
                          Sexp.new(:args),
                          Sexp.new(:scope,
                                   Sexp.new(:block,
                                            Sexp.new(:lasgn, "c",
                                                     Sexp.new(:call,
                                                              "+",
                                                              Sexp.new(:lit, 2, Type.long),
                                                              Sexp.new(:array,
                                                                       Sexp.new(:lit, 3, Type.long)),
                                                              Type.long),
                                                     Type.long),
                                            Type.unknown),
                                   Type.void),
                          Type.function([], Type.void))

  @@conditional1 = 
    Sexp.new(:defn, "conditional1",
             Sexp.new(:args, Sexp.new("arg1", Type.long)),
             Sexp.new(:scope,
                      Sexp.new(:block,
                               Sexp.new(:if,
                                        Sexp.new(:call, "==",
                                                 Sexp.new(:lvar, "arg1", Type.long),
                                                 Sexp.new(:array,
                                                          Sexp.new(:lit, 0, Type.long)),
                                                 Type.bool),
                                        Sexp.new(:return,
                                                 Sexp.new(:lit, 1, Type.long),
                                                 Type.void),
                                        nil, Type.void), Type.unknown), Type.void),
             Type.function([Type.long], Type.long))

  @@conditional2 = Sexp.new(:defn, "conditional2",
                            Sexp.new(:args, Sexp.new("arg1", Type.long)),
                            Sexp.new(:scope,
                                     Sexp.new(:block,
                                              Sexp.new(:if,
                                                       Sexp.new(:call, "==",
                                                                Sexp.new(:lvar, "arg1", Type.long),
                                                                Sexp.new(:array,
                                                                         Sexp.new(:lit, 0, Type.long)),
                                                                Type.bool),
                                                       nil,
                                                       Sexp.new(:return,
                                                                Sexp.new(:lit, 2, Type.long),
                                                                Type.void),
                                                       Type.void),
                                              Type.unknown),
                                     Type.void),
                            Type.function([Type.long], Type.long))

  @@conditional3 = Sexp.new(:defn, "conditional3",
                            Sexp.new(:args, Sexp.new("arg1", Type.long)),
                            Sexp.new(:scope,
                                     Sexp.new(:block,
                                              Sexp.new(:if,
                                                       Sexp.new(:call, "==",
                                                                Sexp.new(:lvar, "arg1", Type.long),
                                                                Sexp.new(:array,
                                                                         Sexp.new(:lit, 0, Type.long)),
                                                                Type.bool),
                                                       Sexp.new(:return,
                                                                Sexp.new(:lit, 3, Type.long),
                                                                Type.void),
                                                       Sexp.new(:return,
                                                                Sexp.new(:lit, 4, Type.long),
                                                                Type.void),
                                                       Type.void),
                                              Type.unknown),
                                     Type.void),
                            Type.function([Type.long], Type.long))

  @@conditional4 = Sexp.new(:defn, "conditional4",
                            Sexp.new(:args, Sexp.new("arg1", Type.long)),
                            Sexp.new(:scope,
                                     Sexp.new(:block,
                                              Sexp.new(:if,
                                                       Sexp.new(:call, "==",
                                                                Sexp.new(:lvar, "arg1", Type.long),
                                                                Sexp.new(:array,
                                                                         Sexp.new(:lit, 0, Type.long)),
                                                                Type.bool),
                                                       Sexp.new(:return,
                                                                Sexp.new(:lit, 2, Type.long),
                                                                Type.void),
                                                       Sexp.new(:if,
                                                                Sexp.new(:call, "<",
                                                                         Sexp.new(:lvar, "arg1", Type.long),
                                                                         Sexp.new(:array,
                                                                                  Sexp.new(:lit, 0, Type.long)),
                                                                         Type.bool),
                                                                Sexp.new(:return,
                                                                         Sexp.new(:lit, 3, Type.long),
                                                                         Type.void),
                                                                Sexp.new(:return,
                                                                         Sexp.new(:lit, 4, Type.long),
                                                                         Type.void),
                                                                Type.void),
                                                       Type.void),
                                              Type.unknown),
                                     Type.void),
                            Type.function([Type.long], Type.long))

  @@__iteration_body = [
    Sexp.new(:args),
    Sexp.new(:scope,
             Sexp.new(:block,
                      Sexp.new(:lasgn, "array",
                               Sexp.new(:array,
                                        Sexp.new(:lit, 1, Type.long),
                                        Sexp.new(:lit, 2, Type.long),
                                        Sexp.new(:lit, 3, Type.long)),
                               Type.long_list),
                      Sexp.new(:iter,
                               Sexp.new(:call,
                                        "each",
                                        Sexp.new(:lvar, "array", Type.long_list),
                                        nil, Type.unknown),
                               Sexp.new(:dasgn_curr, "x", Type.long),
                               Sexp.new(:call, "puts", nil,
                                        Sexp.new(:array,
                                                 Sexp.new(:call,
                                                          "to_s",
                                                          Sexp.new(:dvar, "x", Type.long),
                                                          nil,
                                                          Type.str)),
                                        Type.void),
                               Type.void),
                      Type.unknown),
             Type.void),
    Type.function([], Type.void)]

  @@iteration1 = Sexp.new(:defn, "iteration1", *@@__iteration_body)

  @@iteration2 = Sexp.new(:defn, "iteration2", *@@__iteration_body)

  @@iteration3 = Sexp.new(:defn, "iteration3",
                          Sexp.new(:args),
                          Sexp.new(:scope,
                                   Sexp.new(:block,
                                            Sexp.new(:lasgn, "array1",
                                                     Sexp.new(:array,
                                                              Sexp.new(:lit, 1, Type.long),
                                                              Sexp.new(:lit, 2, Type.long),
                                                              Sexp.new(:lit, 3, Type.long)),
                                                     Type.long_list),
                                            Sexp.new(:lasgn, "array2",
                                                     Sexp.new(:array,
                                                              Sexp.new(:lit, 4, Type.long),
                                                              Sexp.new(:lit, 5, Type.long),
                                                              Sexp.new(:lit, 6, Type.long),
                                                              Sexp.new(:lit, 7, Type.long)),
                                                     Type.long_list),
                                            Sexp.new(:iter,
                                                     Sexp.new(:call,
                                                              "each",
                                                              Sexp.new(:lvar, "array1", Type.long_list),
                                                              nil,
                                                              Type.unknown),
                                                     Sexp.new(:dasgn_curr, "x", Type.long),
                                                     Sexp.new(:iter,
                                                              Sexp.new(:call, "each",
                                                                       Sexp.new(:lvar, "array2", Type.long_list),
                                                                       nil,
                                                                       Type.unknown),
                                                              Sexp.new(:dasgn_curr, "y", Type.long),
                                                              Sexp.new(:block,
                                                                       Sexp.new(:call,
                                                                                "puts",
                                                                                nil,
                                                                                Sexp.new(:array,
                                                                                         Sexp.new(:call,
                                                                                                  "to_s",
                                                                                                  Sexp.new(:dvar, "x", Type.long),
                                                                                                  nil,
                                                                                                  Type.str)),
                                                                                Type.void),
                                                                       Sexp.new(:call,
                                                                                "puts",
                                                                                nil,
                                                                                Sexp.new(:array,
                                                                                         Sexp.new(:call,
                                                                                                  "to_s",
                                                                                                  Sexp.new(:dvar, "y", Type.long),
                                                                                                  nil,
                                                                                                  Type.str)),
                                                                                Type.void),
                                                                       Type.unknown),
                                                              Type.void),
                                                     Type.void),
                                            Type.unknown),
                                   Type.void),
                          Type.function([], Type.void))

  @@multi_args = Sexp.new(:defn, "multi_args",
                          Sexp.new(:args,
                                   Sexp.new("arg1", Type.long),
                                   Sexp.new("arg2", Type.long)),
                          Sexp.new(:scope,
                                   Sexp.new(:block,
                                            Sexp.new(:lasgn,
                                                     "arg3",
                                                     Sexp.new(:call,
                                                              "*",
                                                              Sexp.new(:call,
                                                                       "*",
                                                                       Sexp.new(:lvar, "arg1", Type.long),
                                                                       Sexp.new(:array,
                                                                                Sexp.new(:lvar,
                                                                                         "arg2",
                                                                                         Type.long)),
                                                                       Type.long),
                                                              Sexp.new(:array,
                                                                       Sexp.new(:lit, 7, Type.long)),
                                                              Type.long),
                                                     Type.long),
                                            Sexp.new(:call, "puts",
                                                     nil,
                                                     Sexp.new(:array,
                                                              Sexp.new(:call,
                                                                       "to_s",
                                                                       Sexp.new(:lvar, "arg3", Type.long),
                                                                       nil,
                                                                       Type.str)),
                                                     Type.void),
                                            Sexp.new(:return, Sexp.new(:str, "foo", Type.str),
                                                     Type.void),
                                            Type.unknown),
                                   Type.void),
                          Type.function([Type.long, Type.long], Type.str))

  # TODO: why does return false have type void?
  @@bools = Sexp.new(:defn, "bools",
                     Sexp.new(:args, Sexp.new("arg1", Type.value)),
                     Sexp.new(:scope,
                              Sexp.new(:block,
                                       Sexp.new(:if,
                                                Sexp.new(:call,
                                                         "nil?",
                                                         Sexp.new(:lvar, "arg1", Type.value),
                                                         nil,
                                                         Type.bool),
                                                Sexp.new(:return,
                                                         Sexp.new(:false, Type.bool),
                                                         Type.void),
                                                Sexp.new(:return,
                                                         Sexp.new(:true, Type.bool),
                                                         Type.void),
                                                Type.void),
                                       Type.unknown),
                              Type.void),
                     Type.function([Type.value], Type.bool))

  @@case_stmt = Sexp.new(:defn, "case_stmt",
                         Sexp.new(:args),
                         Sexp.new(:scope,
                                  Sexp.new(:block,
                                           Sexp.new(:lasgn,
                                                    "var",
                                                    Sexp.new(:lit, 2, Type.long),
                                                    Type.long),
                                           Sexp.new(:lasgn,
                                                    "result",
                                                    Sexp.new(:str, "", Type.str),
                                                    Type.str),
                                           Sexp.new(:if,
                                                    Sexp.new(:call,
                                                             "case_equal_long",
                                                             Sexp.new(:lvar, "var", Type.long),
                                                             Sexp.new(:array, Sexp.new(:lit, 1, Type.long)),
                                                             Type.bool),
                                                    Sexp.new(:block,
                                                             Sexp.new(:call,
                                                                      "puts",
                                                                      nil,
                                                                      Sexp.new(:array,
                                                                               Sexp.new(:str, "something", Type.str)),
                                                                      Type.void),
                                                             Sexp.new(:lasgn,
                                                                      "result",
                                                                      Sexp.new(:str, "red", Type.str),
                                                                      Type.str),
                                                             Type.str),
                                                    Sexp.new(:if,
                                                             Sexp.new(:or,
                                                                      Sexp.new(:call,
                                                                               "case_equal_long",
                                                                               Sexp.new(:lvar, "var", Type.long),
                                                                               Sexp.new(:array, Sexp.new(:lit, 2, Type.long)),
                                                                               Type.bool),
                                                                      Sexp.new(:call,
                                                                               "case_equal_long",
                                                                               Sexp.new(:lvar, "var", Type.long),
                                                                               Sexp.new(:array, Sexp.new(:lit, 3, Type.long)),
                                                                               Type.bool),
                                                                      Type.bool),
                                                             Sexp.new(:lasgn,
                                                                      "result",
                                                                      Sexp.new(:str, "yellow", Type.str),
                                                                      Type.str),
                                                             Sexp.new(:if,
                                                                      Sexp.new(:call,
                                                                               "case_equal_long",
                                                                               Sexp.new(:lvar, "var", Type.long),
                                                                               Sexp.new(:array, Sexp.new(:lit, 4, Type.long)),
                                                                               Type.bool),
                                                                      nil,
                                                                      Sexp.new(:lasgn,
                                                                               "result",
                                                                               Sexp.new(:str, "green", Type.str),
                                                                               Type.str),
                                                                      Type.str),
                                                             Type.str),
                                                    Type.str),
                                           Sexp.new(:if,
                                                    Sexp.new(:call,
                                                             "case_equal_str",
                                                             Sexp.new(:lvar, "result", Type.str),
                                                             Sexp.new(:array, Sexp.new(:str, "red", Type.str)),
                                                             Type.bool),
                                                    Sexp.new(:lasgn, "var", Sexp.new(:lit, 1, Type.long), Type.long),
                                                    Sexp.new(:if,
                                                             Sexp.new(:call,
                                                                      "case_equal_str",
                                                                      Sexp.new(:lvar, "result", Type.str),
                                                                      Sexp.new(:array, Sexp.new(:str, "yellow", Type.str)),
                                                                      Type.bool),
                                                             Sexp.new(:lasgn, "var", Sexp.new(:lit, 2, Type.long), Type.long),
                                                             Sexp.new(:if,
                                                                      Sexp.new(:call,
                                                                               "case_equal_str",
                                                                               Sexp.new(:lvar, "result", Type.str),
                                                                               Sexp.new(:array,
                                                                                        Sexp.new(:str, "green", Type.str)),
                                                                               Type.bool),
                                                                      Sexp.new(:lasgn,
                                                                               "var",
                                                                               Sexp.new(:lit, 3, Type.long),
                                                                               Type.long),
                                                                      nil,
                                                                      Type.long),
                                                             Type.long),
                                                    Type.long),
                                           Sexp.new(:return,
                                                    Sexp.new(:lvar, "result", Type.str),
                                                    Type.void),
                                           Type.unknown),
                                  Type.void),
                         Type.function([], Type.str))

  @@eric_is_stubborn = Sexp.new(:defn,
                                "eric_is_stubborn",
                                Sexp.new(:args),
                                Sexp.new(:scope,
                                         Sexp.new(:block,
                                                  Sexp.new(:lasgn,
                                                           "var",
                                                           Sexp.new(:lit,
                                                                    42,
                                                                    Type.long),
                                                           Type.long),
                                                  Sexp.new(:lasgn,
                                                           "var2",
                                                           Sexp.new(:call,
                                                                    "to_s",
                                                                    Sexp.new(:lvar, "var", Type.long),
                                                                    nil,
                                                                    Type.str),
                                                           Type.str),
                                                  Sexp.new(:call,
                                                           "fputs",
                                                           Sexp.new(:gvar,
                                                                    "$stderr",
                                                                    Type.file),
                                                           Sexp.new(:array,
                                                                    Sexp.new(:lvar, "var2", Type.str)),
                                                           Type.unknown),
                                                  Sexp.new(:return,
                                                           Sexp.new(:lvar, "var2", Type.str),
                                                           Type.void),
                                                  Type.unknown),
                                         Type.void),
                                Type.function([], Type.str))

  @@interpolated = Sexp.new(:defn,
                            "interpolated",
                            Sexp.new(:args),
                            Sexp.new(:scope,
                                     Sexp.new(:block,
                                              Sexp.new(:lasgn,
                                                       "var",
                                                       Sexp.new(:lit,
                                                                14,
                                                                Type.long),
                                                       Type.long),
                                              Sexp.new(:lasgn, "var2",
                                                       Sexp.new(:dstr,
                                                                "var is ",
                                                                Sexp.new(:lvar, "var", Type.long),
                                                                Sexp.new(:str, ". So there.", Type.str),
                                                                Type.str),
                                                       Type.str),
                                              Type.unknown),
                                     Type.void),
                            Type.function([], Type.void))

  @@unknown_args = Sexp.new(:defn, "unknown_args",
                            Sexp.new(:args,
                                     Sexp.new("arg1", Type.long),
                                     Sexp.new("arg2", Type.str)),
                            Sexp.new(:scope,
                                     Sexp.new(:block,
                                              Sexp.new(:return,
                                                       Sexp.new(:lvar,
                                                                "arg1",
                                                                Type.long),
                                                       Type.void),
                                              Type.unknown),
                                     Type.void),
                            Type.function([Type.long, Type.str], Type.long))

  @@determine_args = Sexp.new(:defn, "determine_args",
                              Sexp.new(:args),
                              Sexp.new(:scope,
                                       Sexp.new(:block,
                                                Sexp.new(:call,
                                                         "==",
                                                         Sexp.new(:lit,
                                                                  5,
                                                                  Type.long),
                                                         Sexp.new(:array,
                                                                  Sexp.new(:call,
                                                                           "unknown_args",
                                                                           nil,
                                                                           Sexp.new(:array,
                                                                                    Sexp.new(:lit, 4, Type.long),
                                                                                    Sexp.new(:str, "known", Type.str)),
                                                                           Type.long)),
                                                         Type.bool),
                                                Type.unknown),
                                       Type.void),
                              Type.function([], Type.void))

  @@__all = Sexp.new()

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

