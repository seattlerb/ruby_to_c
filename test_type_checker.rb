#!/usr/local/bin/ruby -w

require 'test/unit'
require 'type_checker'
require 'something'

class TestTypeChecker_1 < Test::Unit::TestCase

  def setup
    @type_checker = TypeChecker.new
  end

  def test_args
    @type_checker.env.extend

    input =  [:args, "foo", "bar"]
    output = [:args, ["foo", Type.unknown], ["bar", Type.unknown]],
             [Type.unknown, Type.unknown]

    assert_equal output, @type_checker.process(input)
  end

  def test_args_empty
    input =  [:args]
    output = [:args], []

    assert_equal output, @type_checker.process(input)
  end

  def test_array_single
    add_fake_var "arg1", Type.long

    input  =  [:array, [:lvar, "arg1"]]
    output = [[:array, [:lvar, "arg1", Type.long]], [Type.long]]

    assert_equal output, @type_checker.process(input)
  end

  def test_array_multiple
    add_fake_var "arg1", Type.long
    add_fake_var "arg2", Type.str

    input =  [:array, [:lvar, "arg1"], [:lvar, "arg2"]]
    output = [[:array,
                [:lvar, "arg1", Type.long],
                [:lvar, "arg2", Type.str]],
              [Type.long, Type.str]]

    assert_equal output, @type_checker.process(input)
  end

  def test_call_defined
    add_fake_function "name", Type.long, Type.str
    input  =  [:call, "name", nil, [:array, [:str, "foo"]]]
    output = [[:call, "name", nil, [:array, [:str, "foo"]]], Type.long]

    assert_equal output, @type_checker.process(input)
  end

  def test_call_defined_rhs
    add_fake_function "name", Type.long, Type.long, Type.str
    input  =  [:call, "name", [:lit, 1], [:array, [:str, "foo"]]]
    output = [[:call, "name", [:lit, 1], [:array, [:str, "foo"]]], Type.long]

    assert_equal output, @type_checker.process(input)
  end

  def test_call_undefined
    input  =  [:call, "name", nil, nil]
    output = [[:call, "name", nil, nil], Type.unknown]

    assert_equal output, @type_checker.process(input)
    assert_equal Type.function([], Type.unknown),
                 @type_checker.functions["name"]
  end

  def test_call_unify_1
    add_fake_var "number", Type.long
    input  =  [:call, "==", [:lit, 1], [:array, [:lvar, "number"]]]
    output = [[:call, "==", [:lit, 1],
                [:array, [:lvar, "number", Type.long]]], Type.bool]

    assert_equal output, @type_checker.process(input)
  end

  def test_call_unify_2
    add_fake_var "number1", Type.unknown
    add_fake_var "number2", Type.unknown

    input  =  [:call, "==", [:lit, 1], [:array, [:lvar, "number1"]]]
    output = [[:call, "==", [:lit, 1],
                [:array, [:lvar, "number1", Type.long]]], Type.bool]

    assert_equal output, @type_checker.process(input)

    input  =  [:call, "==", [:lvar, "number2"], [:array, [:lit, 1]]]
    output = [[:call, "==", [:lvar, "number2", Type.long],
                [:array, [:lit, 1]]], Type.bool]

    assert_equal output, @type_checker.process(input)
  end

  def test_call_unify_3
    assert_raises RuntimeError do
      @type_checker.process [:call, "==", [:lit, 1], [:array, [:str, "foo"]]]
    end
  end

  def test_call_case_equal
    add_fake_var "number", Type.unknown
    add_fake_var "string", Type.unknown

    input  =  [:call, "===", [:lit, 1], [:array, [:lvar, "number"]]]
    output = [[:call, "case_equal_long", [:lit, 1],
                [:array, [:lvar, "number", Type.long]]], Type.bool]

    assert_equal output, @type_checker.process(input)

    input  =  [:call, "===", [:str, 'foo'], [:array, [:lvar, "string"]]]
    output = [[:call, "case_equal_str", [:str, 'foo'],
                [:array, [:lvar, "string", Type.str]]], Type.bool]

    assert_equal output, @type_checker.process(input)

  end

  def test_block
    add_fake_function "foo"

    input  =  [:block, [:return, [:nil]]]
    output = [[:block, [:return, [:nil]]], Type.unknown]

    assert_equal output, @type_checker.process(input)
  end

  def test_block_multiple
    add_fake_function "foo"

    input  =  [:block, [:str, "foo"], [:return, [:nil]]]
    output = [[:block, [:str, "foo"], [:return, [:nil]]], Type.unknown]

    assert_equal output, @type_checker.process(input)
  end

  def test_dasgn
    @type_checker.env.extend
    input  =  [:dasgn_curr, "x"]
    output = [[:dasgn_curr, "x", Type.unknown], Type.unknown]

    assert_equal output, @type_checker.process(input)
  end

  def test_defn
    function_type = Type.function [], Type.void
    input  =  [:defn, "empty", [:args], [:scope]]
    output = [[:defn, "empty", [:args], [:scope], function_type],
              function_type]

    assert_equal output, @type_checker.process(input)
  end

  def test_dstr
    add_fake_var "var", Type.str
    input  =  [:dstr, "var is ", [:lvar, "var"], [:str, ". So there."]]
    output = [[:dstr, "var is ", [:lvar, "var", Type.str], [:str, ". So there."]],
              Type.str]

    assert_equal output, @type_checker.process(input)
  end

  def test_dvar
    add_fake_var "dvar", Type.long
    input  =  [:dvar, "dvar"]
    output = [[:dvar, "dvar", Type.long], Type.long]

    assert_equal output, @type_checker.process(input)
  end

  def test_false
    input =   [:true]
    output = [[:true], Type.bool]

    assert_equal output, @type_checker.process(input)
  end

  def test_gvar_defined
    add_fake_gvar "$arg", Type.long
    input  =  [:gvar, "$arg"]
    output = [[:gvar, "$arg", Type.long], Type.long]

    assert_equal output, @type_checker.process(input)
  end

  def test_gvar_undefined
    input  =  [:gvar, "$arg"]
    output = [[:gvar, "$arg", Type.unknown], Type.unknown]

    assert_equal output, @type_checker.process(input)
  end

  def test_if
    input  =  [:if, [:call, "==", [:lit, 1], [:array, [:lit, 2]]],
                    [:str, "not equal"],
                    nil]
    output = [[:if, [:call, "==", [:lit, 1], [:array, [:lit, 2]]],
                    [:str, "not equal"],
                    nil],
              Type.str]

    assert_equal output, @type_checker.process(input)
  end

  def test_if_else
    input  =  [:if, [:call, "==", [:lit, 1], [:array, [:lit, 2]]],
                    [:str, "not equal"],
                    [:str, "equal"]]
    output = [[:if, [:call, "==", [:lit, 1], [:array, [:lit, 2]]],
                    [:str, "not equal"],
                    [:str, "equal"]],
              Type.str]

    assert_equal output, @type_checker.process(input)
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
    output = [[:iter,
                [:call, "each", [:lvar, "array", var_type], nil],
                [:dasgn_curr, "x", Type.long],
                [:call, "puts", nil, [:array,
                   [:call, "to_s", [:dvar, "x", Type.long], nil]]]],
              Type.void]

    assert_equal output, @type_checker.process(input)
  end

  def test_lasgn
    @type_checker.env.extend
    input  =  [:lasgn, "var", [:str, "foo"]]
    output = [[:lasgn, "var", [:str, "foo"], Type.str], Type.str]

    assert_equal output, @type_checker.process(input)
  end
  
  def test_lasgn_array
    @type_checker.env.extend
    input  =  [:lasgn, "var", [:array, [:str, "foo"], [:str, "bar"]]]
    output_type = Type.str_list
    output = [[:lasgn, "var",
                [:array, [:str, "foo"], [:str, "bar"]], output_type],
              output_type]

    assert_equal output, @type_checker.process(input)
  end

  def test_lit
    input  =  [:lit, 1]
    output = [[:lit, 1], Type.long]

    assert_equal output, @type_checker.process(input)
  end

  def test_lvar
    add_fake_var "arg", Type.long
    input  =  [:lvar, "arg"]
    output = [[:lvar, "arg", Type.long], Type.long]

    assert_equal output, @type_checker.process(input)
  end

  def test_nil
    input  =  [:nil]
    output = [[:nil], Type.value]

    assert_equal output, @type_checker.process(input)
  end

  def test_return
    add_fake_function "foo"

    input =   [:return, [:nil]]
    output = [[:return, [:nil]], Type.void]

    assert_equal output, @type_checker.process(input)
  end

  def test_return_raises
    input =   [:return, [:nil]]

    assert_raises RuntimeError do
      @type_checker.process(input)
    end
  end

  def test_str
    input  =  [:str, "foo"]
    output = [[:str, "foo"], Type.str]

    assert_equal output, @type_checker.process(input)
  end

  def test_scope
    add_fake_function "foo"
    input =   [:scope, [:block, [:return, [:nil]]]]
    output = [[:scope, [:block, [:return, [:nil]]]], Type.void]

    assert_equal output, @type_checker.process(input)
  end

  def test_scope_empty
    input =   [:scope]
    output = [[:scope], Type.void]

    assert_equal output, @type_checker.process(input)
  end

  def test_true
    input =   [:true]
    output = [[:true], Type.bool]

    assert_equal output, @type_checker.process(input)
  end

  def test_unless
    input  =  [:if, [:call, "==", [:lit, 1], [:array, [:lit, 2]]],
                    nil,
                    [:str, "equal"]]
    output = [[:if, [:call, "==", [:lit, 1], [:array, [:lit, 2]]],
                    nil,
                    [:str, "equal"]],
              Type.str]

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

  @@missing = [nil]

  @@empty = [:defn, "empty",
      [:args],
      [:scope],
      Type.function([], Type.void)],
    Type.function([], Type.void)

  @@stupid = [:defn, "stupid",
      [:args],
      [:scope,
        [:block,
          [:return, [:nil]]]],
      Type.function([], Type.value)],
    Type.function([], Type.value)

  @@simple = [:defn, "simple",
      [:args, ["arg1", Type.str]],
        [:scope,
          [:block,
            [:call, "print", nil, [:array, [:lvar, "arg1", Type.str]]],
            [:call, "puts", nil, [:array,
              [:call, "to_s",
                [:call, "+", [:lit, 4], [:array, [:lit, 2]]], nil]]]]],
      Type.function([Type.str], Type.void)],
  Type.function([Type.str], Type.void)

  @@global = [:defn, "global",
      [:args],
      [:scope,
        [:block,
          [:call, "fputs",
            [:gvar, "$stderr", Type.file],
            [:array, [:str, "blah"]]]]],
      Type.function([], Type.void)],
    Type.function([], Type.void)

  @@lasgn_call = [:defn, "lasgn_call",
      [:args],
        [:scope,
          [:block,
            [:lasgn, "c",
              [:call, "+", [:lit, 2], [:array, [:lit, 3]]],
           Type.long]]],
      Type.function([], Type.void)],
    Type.function([], Type.void)

  @@conditional1 = [:defn, "conditional1",
      [:args, ["arg1", Type.long]],
      [:scope,
        [:block,
          [:if,
            [:call, "==",
              [:lvar, "arg1", Type.long],
              [:array, [:lit, 0]]],
            [:return, [:lit, 1]],
            nil]]],
      Type.function([Type.long], Type.long)],
    Type.function([Type.long], Type.long)

  @@conditional2 = [:defn, "conditional2",
      [:args, ["arg1", Type.long]],
      [:scope,
        [:block,
          [:if,
            [:call, "==",
              [:lvar, "arg1", Type.long],
              [:array, [:lit, 0]]],
            nil,
            [:return, [:lit, 2]]]]],
      Type.function([Type.long], Type.long)],
    Type.function([Type.long], Type.long)

  @@conditional3 = [:defn, "conditional3",
      [:args, ["arg1", Type.long]],
      [:scope,
        [:block,
          [:if,
            [:call, "==",
              [:lvar, "arg1", Type.long],
              [:array, [:lit, 0]]],
            [:return, [:lit, 3]],
            [:return, [:lit, 4]]]]],
      Type.function([Type.long], Type.long)],
    Type.function([Type.long], Type.long)

  @@conditional4 = [:defn, "conditional4",
      [:args, ["arg1", Type.long]],
      [:scope,
        [:block,
          [:if,
            [:call, "==",
              [:lvar, "arg1", Type.long],
              [:array, [:lit, 0]]],
            [:return, [:lit, 2]],
            [:if,
              [:call, "<",
                [:lvar, "arg1", Type.long],
                [:array, [:lit, 0]]],
              [:return, [:lit, 3]],
              [:return, [:lit, 4]]]]]],
      Type.function([Type.long], Type.long)],
    Type.function([Type.long], Type.long)

  @@iteration_body = [[:args], [:scope,
      [:block,
        [:lasgn, "array",
          [:array, [:lit, 1], [:lit, 2], [:lit, 3]],
          Type.long_list],
      [:iter,
        [:call, "each", [:lvar, "array", Type.long_list], nil],
        [:dasgn_curr, "x", Type.long],
        [:call, "puts", nil,
          [:array, [:call, "to_s", [:dvar, "x", Type.long], nil]]]]]],
      Type.function([], Type.void)]

  @@iteration1 = [:defn, "iteration1", *@@iteration_body],
    Type.function([], Type.void)

  @@iteration2 = [:defn, "iteration2", *@@iteration_body],
    Type.function([], Type.void)

  @@iteration3 = [:defn, "iteration3",
      [:args],
        [:scope,
        [:block,
          [:lasgn, "array1",
            [:array, [:lit, 1], [:lit, 2], [:lit, 3]],
            Type.long_list],
          [:lasgn, "array2",
            [:array, [:lit, 4], [:lit, 5], [:lit, 6], [:lit, 7]],
            Type.long_list],
          [:iter,
            [:call, "each", [:lvar, "array1", Type.long_list], nil],
            [:dasgn_curr, "x", Type.long],
              [:iter,
                [:call, "each",
                  [:lvar, "array2", Type.long_list], nil],
                [:dasgn_curr, "y", Type.long],
                [:block,
                  [:call, "puts", nil,
                    [:array,
                      [:call, "to_s",
                        [:dvar, "x", Type.long], nil]]],
                  [:call, "puts", nil,
                    [:array,
                      [:call, "to_s",
                        [:dvar, "y", Type.long], nil]]]]]]]],
      Type.function([], Type.void)],
    Type.function([], Type.void)

  @@multi_args = [:defn, "multi_args",
      [:args, ["arg1", Type.long], ["arg2", Type.long]],
        [:scope,
          [:block,
            [:lasgn, "arg3",
              [:call, "*",
                [:call, "*",
                  [:lvar, "arg1", Type.long],
                  [:array, [:lvar, "arg2", Type.long]]],
                [:array, [:lit, 7]]],
              Type.long],
            [:call, "puts",
              nil,
              [:array,
                [:call, "to_s", [:lvar, "arg3", Type.long], nil]]],
            [:return, [:str, "foo"]]]],
      Type.function([Type.long, Type.long], Type.str)],
    Type.function([Type.long, Type.long], Type.str)

  @@bools = [:defn, "bools",
      [:args, ["arg1", Type.value]],
      [:scope,
        [:block,
          [:if,
            [:call, "nil?", [:lvar, "arg1", Type.value], nil],
            [:return, [:false]],
            [:return, [:true]]]]],
      Type.function([Type.value], Type.bool)],
    Type.function([Type.value], Type.bool)

  @@case_stmt = [:defn, "case_stmt",
      [:args],
      [:scope,
        [:block,
          [:lasgn, "var", [:lit, 2], Type.long],
          [:lasgn, "result", [:str, ""], Type.str],
          [:if,
            [:call, "case_equal_long",
            [:lvar, "var", Type.long], [:array, [:lit, 1]]],
            [:block,
              [:call, "puts",
                nil, [:array, [:str, "something"]]],
              [:lasgn, "result", [:str, "red"], Type.str]],
            [:if,
              [:or,
                [:call, "case_equal_long",
                [:lvar, "var", Type.long], [:array, [:lit, 2]]],
                [:call, "case_equal_long",
                [:lvar, "var", Type.long], [:array, [:lit, 3]]]],
              [:lasgn, "result", [:str, "yellow"], Type.str],
              [:if,
                [:call, "case_equal_long",
                [:lvar, "var", Type.long], [:array, [:lit, 4]]],
                nil,
                [:lasgn, "result", [:str, "green"], Type.str]]]],

          [:if,
            [:call, "case_equal_str",
            [:lvar, "result", Type.str], [:array, [:str, "red"]]],
            [:lasgn, "var", [:lit, 1], Type.long],
            [:if,
              [:call, "case_equal_str",
              [:lvar, "result", Type.str], [:array, [:str, "yellow"]]],
              [:lasgn, "var", [:lit, 2], Type.long],
              [:if,
                [:call, "case_equal_str",
                [:lvar, "result", Type.str], [:array, [:str, "green"]]],
                [:lasgn, "var", [:lit, 3], Type.long],
                nil]]],
          [:return, [:lvar, "result", Type.str]]]],
      Type.function([], Type.str)],
    Type.function([], Type.str)

  # HACK: Type.str is the correct return type
  @@eric_is_stubborn = [:defn, "eric_is_stubborn",
      [:args],
      [:scope,
        [:block,
          [:lasgn, "var",
            [:lit, 42], Type.long],
          [:lasgn, "var2",
            [:call, "to_s", [:lvar, "var", Type.long], nil], Type.str],
          [:call, "fputs",
            [:gvar, "$stderr", Type.file],
            [:array, [:lvar, "var2", Type.str]]],
          [:return, [:lvar, "var2", Type.str]]]],
      Type.function([], Type.str)],
    Type.function([], Type.str)

  @@interpolated = [:defn, "interpolated",
      [:args],
      [:scope,
        [:block,
          [:lasgn, "var", [:lit, 14], Type.long],
          [:lasgn, "var2",
            [:dstr,
              "var is ",
              [:lvar, "var", Type.long],
              [:str, ". So there."]],
            Type.str]]],
      Type.function([], Type.void)],
      Type.function([], Type.void)

  @@unknown_args = [:defn, "unknown_args",
    [:args, ["arg1", Type.long], ["arg2", Type.str]],
    [:scope,
      [:block,
        [:return, [:lvar, "arg1", Type.long]]]],
        Type.function([Type.long, Type.str], Type.long)],
    Type.function([Type.long, Type.str], Type.long)

  @@determine_args = [:defn, "determine_args",
      [:args],
      [:scope,
        [:block,
          [:call, "==", [:lit, 5],
            [:array,
              [:call, "unknown_args", nil,
                [:array,
                  [:lit, 4], [:str, "known"]]]]]]],
      Type.function([], Type.void)],
    Type.function([], Type.void)

  @@__all = []

  @@__parser = ParseTree.new
  @@__rewriter = Rewriter.new
  @@__type_checker = TypeChecker.new

  Something.instance_methods(false).sort.each do |meth|
    if class_variables.include?("@@#{meth}") then
      @@__all << eval("@@#{meth}")
      eval "def test_#{meth}
        
        assert_equal @@#{meth}, @@__type_checker.process(@@__rewriter.process(@@__parser.parse_tree(Something, :#{meth})))
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

