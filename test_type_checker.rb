#!/usr/local/bin/ruby -w

require 'test/unit'
require 'type_checker'
require 'something'

# Test::Unit::Assertions.use_pp = false

# TODO: clean up all from_array crap calls

class TestTypeChecker_1 < Test::Unit::TestCase

  def setup
    @type_checker = TypeChecker.new
  end

  def test_args
    @type_checker.env.extend

    input =  [:args, "foo", "bar"]
    output = Sexp.new(:args, Sexp.new("foo", Type.unknown), Sexp.new("bar", Type.unknown))

    assert_equal output, @type_checker.process(input)
  end

  def test_args_empty
    input =  [:args]
    output = Sexp.new(:args)
    # TODO: this should be superseded by the new array functionality

    assert_equal output, @type_checker.process(input)
  end

  def test_array_single
    add_fake_var "arg1", Type.long

    input  =  [:array, [:lvar, "arg1"]]
    output = Sexp.new(:array, Sexp.new(:lvar, "arg1", Type.long))

    result = @type_checker.process(input)

    assert_equal Type.homo, result.sexp_type    
    assert_equal [ Type.long ], result.sexp_types
    assert_equal output, result
  end

  def test_array_multiple
    add_fake_var "arg1", Type.long
    add_fake_var "arg2", Type.str

    input =  [:array, [:lvar, "arg1"], [:lvar, "arg2"]]
    output = Sexp.new(:array,
                      Sexp.new(:lvar, "arg1", Type.long),
                      Sexp.new(:lvar, "arg2", Type.str))

    assert_equal output, @type_checker.process(input)
  end

  def test_call_defined
    add_fake_function "name", Type.long, Type.str
    input  =  [:call, "name", nil, [:array, [:str, "foo"]]]
    output = [:call, "name", nil, [:array, [:str, "foo", Type.str]], Type.long]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_call_defined_rhs
    add_fake_function "name", Type.long, Type.long, Type.str
    input  =  [:call, "name", [:lit, 1], [:array, [:str, "foo"]]]
    output = [:call, "name", [:lit, 1, Type.long], [:array, [:str, "foo", Type.str]], Type.long]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_call_undefined
    input  =  [:call, "name", nil, nil]
    output = [:call, "name", nil, nil, Type.unknown]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
    assert_equal Type.function([], Type.unknown), # FIX returns unknown in []
                 @type_checker.functions["name"]
  end

  def test_call_unify_1
    add_fake_var "number", Type.long
    input  =  [:call, "==", [:lit, 1], [:array, [:lvar, "number"]]]
    output = [:call, "==",
      [:lit, 1, Type.long],
      [:array, [:lvar, "number", Type.long]], Type.bool]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_call_unify_2
    add_fake_var "number1", Type.unknown
    add_fake_var "number2", Type.unknown

    input  =  [:call, "==", [:lit, 1], [:array, [:lvar, "number1"]]]
    output = [:call, "==", [:lit, 1, Type.long],
                [:array, [:lvar, "number1", Type.long]], Type.bool]

    assert_equal Sexp.from_array(output), @type_checker.process(input)

    input  =  [:call, "==", [:lvar, "number2"], [:array, [:lit, 1]]]
    output = [:call, "==", [:lvar, "number2", Type.long],
                [:array, [:lit, 1, Type.long]], Type.bool]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_call_case_equal
    add_fake_var "number", Type.unknown
    add_fake_var "string", Type.unknown

    input  =  [:call, "===", [:lit, 1], [:array, [:lvar, "number"]]]
    output = [:call, "case_equal_long", [:lit, 1, Type.long],
                [:array, [:lvar, "number", Type.long]], Type.bool]

    assert_equal Sexp.from_array(output), @type_checker.process(input)

    input  =  [:call, "===", [:str, 'foo'], [:array, [:lvar, "string"]]]
    output = [:call, "case_equal_str", [:str, 'foo', Type.str],
                [:array, [:lvar, "string", Type.str]], Type.bool]

    assert_equal Sexp.from_array(output), @type_checker.process(input)

  end

  def test_block
    add_fake_function "foo"

    input  =  [:block, [:return, [:nil]]]
    # FIX: should this really be void for return?
    output = [:block, [:return, [:nil, Type.value], Type.void], Type.unknown]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_block_multiple
    add_fake_function "foo"

    input  =  [:block, [:str, "foo"], [:return, [:nil]]]
    output = [:block, [:str, "foo", Type.str], [:return, [:nil, Type.value], Type.void], Type.unknown]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_dasgn
    @type_checker.env.extend
    input  =  [:dasgn_curr, "x"]
    output = [:dasgn_curr, "x", Type.unknown]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
    # HACK: is this a valid test??? it was in ruby_to_c:
    # assert_equal Type.long, @type_checker.env.lookup("x")
  end

  def test_defn
    function_type = Type.function [], Type.void
    input  =  [:defn, "empty", [:args], [:scope]]
    output = Sexp.new(:defn,
                      "empty",
                      Sexp.new(:args),
                      Sexp.new(:scope, Type.void),
                      function_type)

    assert_equal output, @type_checker.process(input)
  end

  def test_dstr
    add_fake_var "var", Type.str
    input  = [:dstr, "var is ", [:lvar, "var"], [:str, ". So there."]]
    output = Sexp.new(:dstr, "var is ",
                      Sexp.new(:lvar, "var", Type.str),
                      Sexp.new(:str, ". So there.", Type.str),
                      Type.str)

    assert_equal output, @type_checker.process(input)
  end

  def test_dvar
    add_fake_var "dvar", Type.long
    input  =  [:dvar, "dvar"]
    output = [:dvar, "dvar", Type.long]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_false
    input =   [:false]
    output = [:false, Type.bool]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_gvar_defined
    add_fake_gvar "$arg", Type.long
    input  =  [:gvar, "$arg"]
    output = [:gvar, "$arg", Type.long]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_gvar_undefined
    input  =  [:gvar, "$arg"]
    output = [:gvar, "$arg", Type.unknown]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_if
    input  =  [:if, [:call, "==", [:lit, 1], [:array, [:lit, 2]]],
                    [:str, "not equal"],
                    nil]
    output = [:if, [:call, "==", [:lit, 1, Type.long], [:array, [:lit, 2, Type.long]], Type.bool],
                    [:str, "not equal", Type.str],
                    nil,
              Type.str]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_if_else
    input  =  [:if, [:call, "==", [:lit, 1], [:array, [:lit, 2]]],
                    [:str, "not equal"],
                    [:str, "equal"]]
    output = [:if, [:call, "==", [:lit, 1, Type.long], [:array, [:lit, 2, Type.long]], Type.bool],
                    [:str, "not equal", Type.str],
                    [:str, "equal", Type.str],
              Type.str]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_iter
    @type_checker.env.extend
    var_type = Type.long_list
    add_fake_var "array", var_type
    input  =  [:iter,
                [:call, "each", [:lvar, "array"], nil],
                [:dasgn_curr, "x"],
                [:call, "puts", nil, [:array,
                   [:call, "to_s", [:dvar, "x"], nil]]]]
    output = [:iter,
                [:call, "each", [:lvar, "array", var_type], nil, Type.unknown],
                [:dasgn_curr, "x", Type.long],
                [:call, "puts", nil, [:array,
                   [:call, "to_s", [:dvar, "x", Type.long], nil, Type.str]], Type.void],
              Type.void]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_lasgn
    @type_checker.env.extend # FIX: this is a design flaw... examine irb sess:
    # require 'sexp_processor'
    # require 'type_checker'
    # tc = TypeChecker.new
    # a = [:lasgn, "var", [:str, "foo"]]
    # s = Sexp.from_array(a)
    # tc.process(s)
    # => raises
    # tc.env.extend
    # tc.process(s)
    # => raises elsewhere... etc etc etc
    # makes debugging very difficult
    input  =  [:lasgn, "var", [:str, "foo"]]
    output = Sexp.new(:lasgn, "var", 
                      Sexp.new(:str, "foo", Type.str),
                      Type.str)

    assert_equal output, @type_checker.process(input)
  end
  
  def test_lasgn_array
    @type_checker.env.extend
    input  =  [:lasgn, "var", [:array, [:str, "foo"], [:str, "bar"]]]
    output = Sexp.new(:lasgn, "var",
                      Sexp.new(:array,
                               Sexp.new(:str, "foo", Type.str),
                               Sexp.new(:str, "bar", Type.str)),
                      Type.str_list)

    assert_equal output, @type_checker.process(input)
  end

  def test_lit
    input  =  [:lit, 1]
    output = [:lit, 1, Type.long]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_lvar
    add_fake_var "arg", Type.long
    input  =  [:lvar, "arg"]
    output = [:lvar, "arg", Type.long]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_nil
    input  =  [:nil]
    output = [:nil, Type.value]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_return
    add_fake_function "foo"

    input =   [:return, [:nil]]
    output = [:return, [:nil, Type.value], Type.void]

    x = Sexp.from_array(output)

    assert_equal x, @type_checker.process(input)
  end

  def test_return_raises
    input =   [:return, [:nil]]

    assert_raises RuntimeError do
      @type_checker.process(input)
    end
  end

  def test_str
    input  =  [:str, "foo"]
    output = [:str, "foo", Type.str]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_scope
    add_fake_function "foo"
    input  = [:scope, [:block, [:return, [:nil]]]]
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
    input =   [:scope]
    output = [:scope, Type.void]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_true
    input =  [:true]
    output = [:true, Type.bool]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
  end

  def test_unless
    input  =  [:if, [:call, "==", [:lit, 1], [:array, [:lit, 2]]],
                    nil,
                    [:str, "equal"]]
    output = [:if, [:call, "==", 
        [:lit, 1, Type.long],
        [:array, [:lit, 2, Type.long]], Type.bool], nil, [:str, "equal", Type.str], Type.str]

    assert_equal Sexp.from_array(output), @type_checker.process(input)
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

  @@missing = [nil]

  @@empty = [:defn, "empty",
      [:args],
      [:scope, Type.void],
      Type.function([], Type.void)]

  @@stupid = [:defn, "stupid",
      [:args],
      [:scope,
        [:block,
          [:return, [:nil, Type.value], Type.void], Type.unknown], Type.void],
      Type.function([], Type.value)]

  @@simple = [:defn, "simple",
      [:args, ["arg1", Type.str]],
        [:scope,
          [:block,
            [:call, "print", nil, [:array, [:lvar, "arg1", Type.str]], Type.void],
            [:call, "puts", nil, [:array,
              [:call, "to_s",
                [:call, "+", [:lit, 4, Type.long], [:array, [:lit, 2, Type.long]], Type.long],
              nil, Type.str]], Type.void], Type.unknown], Type.void],
      Type.function([Type.str], Type.void)]

  @@global = [:defn, "global",
      [:args],
      [:scope,
        [:block,
          [:call, "fputs",
            [:gvar, "$stderr", Type.file],
            [:array, [:str, "blah", Type.str]], Type.unknown], Type.unknown], Type.void],
      Type.function([], Type.void)]

  @@lasgn_call = [:defn, "lasgn_call",
      [:args],
        [:scope,
          [:block,
            [:lasgn, "c",
              [:call, "+", [:lit, 2, Type.long], [:array, [:lit, 3, Type.long]], Type.long],
           Type.long], Type.unknown], Type.void],
      Type.function([], Type.void)]

  @@conditional1 = [:defn, "conditional1",
      [:args, ["arg1", Type.long]],
      [:scope,
        [:block,
          [:if,
            [:call, "==",
              [:lvar, "arg1", Type.long],
              [:array, [:lit, 0, Type.long]], Type.bool],
            [:return, [:lit, 1, Type.long], Type.void],
            nil, Type.void], Type.unknown], Type.void],
      Type.function([Type.long], Type.long)]

  @@conditional2 = [:defn, "conditional2",
      [:args, ["arg1", Type.long]],
      [:scope,
        [:block,
          [:if,
            [:call, "==",
              [:lvar, "arg1", Type.long],
              [:array, [:lit, 0, Type.long]], Type.bool],
            nil,
            [:return, [:lit, 2, Type.long], Type.void], Type.void], Type.unknown], Type.void],
      Type.function([Type.long], Type.long)]

  @@conditional3 = [:defn, "conditional3",
      [:args, ["arg1", Type.long]],
      [:scope,
        [:block,
          [:if,
            [:call, "==",
              [:lvar, "arg1", Type.long],
              [:array, [:lit, 0, Type.long]], Type.bool],
            [:return, [:lit, 3, Type.long], Type.void],
            [:return, [:lit, 4, Type.long], Type.void], Type.void], Type.unknown], Type.void],
      Type.function([Type.long], Type.long)]

  @@conditional4 = [:defn, "conditional4",
      [:args, ["arg1", Type.long]],
      [:scope,
        [:block,
          [:if,
            [:call, "==",
              [:lvar, "arg1", Type.long],
              [:array, [:lit, 0, Type.long]], Type.bool],
            [:return, [:lit, 2, Type.long], Type.void],
            [:if,
              [:call, "<",
                [:lvar, "arg1", Type.long],
                [:array, [:lit, 0, Type.long]], Type.bool],
              [:return, [:lit, 3, Type.long], Type.void],
              [:return, [:lit, 4, Type.long], Type.void], Type.void], Type.void], Type.unknown], Type.void],
      Type.function([Type.long], Type.long)]

  @@iteration_body = [[:args], [:scope,
      [:block,
        [:lasgn, "array",
          [:array, [:lit, 1, Type.long], [:lit, 2, Type.long], [:lit, 3, Type.long]],
          Type.long_list],
      [:iter,
        [:call, "each", [:lvar, "array", Type.long_list], nil, Type.unknown],
        [:dasgn_curr, "x", Type.long],
        [:call, "puts", nil,
          [:array, [:call, "to_s", [:dvar, "x", Type.long], nil, Type.str]], Type.void], Type.void], Type.unknown], Type.void],
      Type.function([], Type.void)]

  @@iteration1 = [:defn, "iteration1", *@@iteration_body]

  @@iteration2 = [:defn, "iteration2", *@@iteration_body]

  @@iteration3 = [:defn, "iteration3",
      [:args],
        [:scope,
        [:block,
          [:lasgn, "array1",
            [:array,
              [:lit, 1, Type.long],
              [:lit, 2, Type.long],
              [:lit, 3, Type.long]],
            Type.long_list],
          [:lasgn, "array2",
            [:array,
              [:lit, 4, Type.long],
              [:lit, 5, Type.long],
              [:lit, 6, Type.long],
              [:lit, 7, Type.long]],
            Type.long_list],
          [:iter,
            [:call, "each", [:lvar, "array1", Type.long_list], nil, Type.unknown],
            [:dasgn_curr, "x", Type.long],
              [:iter,
                [:call, "each",
                  [:lvar, "array2", Type.long_list], nil, Type.unknown],
                [:dasgn_curr, "y", Type.long],
                [:block,
                  [:call, "puts", nil,
                    [:array,
                      [:call, "to_s",
                        [:dvar, "x", Type.long], nil, Type.str]], Type.void],
                  [:call, "puts", nil,
                    [:array,
                      [:call, "to_s",
                        [:dvar, "y", Type.long], nil, Type.str]], Type.void], Type.unknown], Type.void], Type.void], Type.unknown], Type.void],
      Type.function([], Type.void)]

  @@multi_args = [:defn, "multi_args",
      [:args, ["arg1", Type.long], ["arg2", Type.long]],
        [:scope,
          [:block,
            [:lasgn, "arg3",
              [:call, "*",
                [:call, "*",
                  [:lvar, "arg1", Type.long],
                  [:array, [:lvar, "arg2", Type.long]], Type.long],
                [:array, [:lit, 7, Type.long]], Type.long],
              Type.long],
            [:call, "puts",
              nil,
              [:array,
                [:call, "to_s", [:lvar, "arg3", Type.long], nil, Type.str]], Type.void],
            [:return, [:str, "foo", Type.str], Type.void], Type.unknown], Type.void],
      Type.function([Type.long, Type.long], Type.str)]

  # TODO: why does return false have type void?
  @@bools = [:defn, "bools",
      [:args, ["arg1", Type.value]],
      [:scope,
        [:block,
          [:if,
            [:call, "nil?", [:lvar, "arg1", Type.value], nil, Type.bool],
            [:return, [:false, Type.bool], Type.void],
            [:return, [:true, Type.bool], Type.void], Type.void], Type.unknown], Type.void],
      Type.function([Type.value], Type.bool)]

  @@case_stmt = [:defn, "case_stmt",
      [:args],
      [:scope,
        [:block,
          [:lasgn, "var", [:lit, 2, Type.long], Type.long],
          [:lasgn, "result", [:str, "", Type.str], Type.str],
          [:if,
            [:call, "case_equal_long",
            [:lvar, "var", Type.long], [:array, [:lit, 1, Type.long]], Type.bool],
            [:block,
              [:call, "puts",
                nil, [:array, [:str, "something", Type.str]], Type.void],
              [:lasgn, "result", [:str, "red", Type.str], Type.str], Type.str],
            [:if,
              [:or,
                [:call, "case_equal_long",
                [:lvar, "var", Type.long], [:array, [:lit, 2, Type.long]], Type.bool],
                [:call, "case_equal_long",
                [:lvar, "var", Type.long], [:array, [:lit, 3, Type.long]], Type.bool], Type.bool],
              [:lasgn, "result", [:str, "yellow", Type.str], Type.str],
              [:if,
                [:call, "case_equal_long",
                [:lvar, "var", Type.long], [:array, [:lit, 4, Type.long]], Type.bool],
                nil,
                [:lasgn, "result", [:str, "green", Type.str], Type.str], Type.str], Type.str], Type.str],

          [:if,
            [:call, "case_equal_str",
            [:lvar, "result", Type.str], [:array, [:str, "red", Type.str]], Type.bool],
            [:lasgn, "var", [:lit, 1, Type.long], Type.long],
            [:if,
              [:call, "case_equal_str",
              [:lvar, "result", Type.str], [:array, [:str, "yellow", Type.str]], Type.bool],
              [:lasgn, "var", [:lit, 2, Type.long], Type.long],
              [:if,
                [:call, "case_equal_str",
                [:lvar, "result", Type.str], [:array, [:str, "green", Type.str]], Type.bool],
                [:lasgn, "var", [:lit, 3, Type.long], Type.long],
                nil, Type.long], Type.long], Type.long],
          [:return, [:lvar, "result", Type.str], Type.void], Type.unknown], Type.void],
      Type.function([], Type.str)]

  @@eric_is_stubborn = [:defn, "eric_is_stubborn",
      [:args],
      [:scope,
        [:block,
          [:lasgn, "var",
            [:lit, 42, Type.long], Type.long],
          [:lasgn, "var2",
            [:call, "to_s", [:lvar, "var", Type.long], nil, Type.str], Type.str],
          [:call, "fputs",
            [:gvar, "$stderr", Type.file],
            [:array, [:lvar, "var2", Type.str]], Type.unknown],
          [:return, [:lvar, "var2", Type.str], Type.void], Type.unknown], Type.void],
      Type.function([], Type.str)]

  @@interpolated = [:defn, "interpolated",
      [:args],
      [:scope,
        [:block,
          [:lasgn, "var", [:lit, 14, Type.long], Type.long],
          [:lasgn, "var2",
            [:dstr,
              "var is ",
              [:lvar, "var", Type.long],
              [:str, ". So there.", Type.str], Type.str], Type.str], Type.unknown], Type.void],
      Type.function([], Type.void)]

  @@unknown_args = [:defn, "unknown_args",
    [:args, ["arg1", Type.long], ["arg2", Type.str]],
    [:scope,
      [:block,
        [:return, [:lvar, "arg1", Type.long], Type.void], Type.unknown], Type.void],
        Type.function([Type.long, Type.str], Type.long)]

  @@determine_args = [:defn, "determine_args",
      [:args],
      [:scope,
        [:block,
          [:call, "==", [:lit, 5, Type.long],
            [:array,
              [:call, "unknown_args", nil,
                [:array,
                  [:lit, 4, Type.long], [:str, "known", Type.str]], Type.long]], Type.bool], Type.unknown], Type.void],
      Type.function([], Type.void)]

  @@__all = []

  @@__type_checker = TypeChecker.new

  Something.instance_methods(false).sort.each do |meth|
    if class_variables.include?("@@#{meth}") then
      @@__all << eval("@@#{meth}")
      eval "def test_#{meth}
        exp = @@__type_checker.translate Something, :#{meth}
        assert_equal Sexp.from_array(@@#{meth}), exp
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

