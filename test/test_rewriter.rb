#!/usr/local/bin/ruby -w

$TESTING = true

require 'rewriter'
require 'r2ctestcase'
require 'pt_testcase'

ParseTreeTestCase.testcase_order << "Rewriter"

class TestRewriter < ParseTreeTestCase
  def setup
    super
    @processor = Rewriter.new
  end

  add_test("alias",
           s(:class, :X, nil, s(:scope, s(:alias, s(:lit, :y), s(:lit, :x)))))

  add_test("and",
           s(:and, s(:call, nil, :a, nil), s(:call, nil, :b, nil)))

  add_test("argscat",
           s(:lasgn,
             :a,
             s(:svalue,
               s(:argscat,
                 s(:array, s(:call, nil, :b, nil), s(:call, nil, :c, nil)),
                 s(:call, nil, :d, nil)))))

  add_test("argspush",
           s(:call,
             s(:call, nil, :a, nil),
             :[]=,
             s(:arglist,
               s(:splat, s(:call, nil, :b, nil)), s(:call, nil, :c, nil))))

  add_test("array",
           s(:array, s(:lit, 1), s(:lit, :b), s(:str, "c")))

  add_test("attrasgn",
           s(:block,
             s(:lasgn, :y, s(:lit, 0)),
             s(:call, s(:lit, 42), :method=, s(:arglist, s(:lvar, :y)))))

  add_test("attrasgn_index_equals",
           s(:call, s(:call, nil, :a, nil), :[]=,
             s(:arglist, s(:lit, 42), s(:lit, 24))))

  add_test("attrset",
           s(:defn,
             :writer=,
             s(:args, :arg),
             s(:scope,
               s(:block,
                 s(:return, s(:iasgn, :@writer, s(:lvar, :arg)))))))

  add_test("back_ref",
           s(:array,
             s(:back_ref, "&".intern),
             s(:back_ref, "`".intern),
             s(:back_ref, "'".intern),
             s(:back_ref, "+".intern)))

  add_test("begin",
           s(:begin, s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1)))))

  add_test("block_pass",
           s(:block_pass, s(:call, nil, :b, nil), s(:call, nil, :a, nil)))

  add_test("bmethod",
           s(:defn,
             :unsplatted,
             s(:args, :x),
             s(:scope,
               s(:block, s(:call, s(:lvar, :x), :+, s(:arglist, s(:lit, 1)))))))

  add_test("bmethod_splat",
           s(:defn, :splatted,
             s(:args, :"*args"),
             s(:scope,
               s(:block,
                 s(:lasgn, :y, s(:call, s(:lvar, :args), :first, nil)),
                 s(:call, s(:lvar, :y), :+, s(:arglist, s(:lit, 42)))))))

  add_test("break",
           s(:iter,
             s(:call, nil, :loop, nil),
             s(:dasgn_curr, :temp_1),
             s(:if, s(:true), s(:break), nil)))

  add_test("break_arg",
           s(:iter,
             s(:call, nil, :loop, nil),
             s(:dasgn_curr, :temp_1),
             s(:if, s(:true), s(:break, s(:lit, 42)), nil)))

  add_test("call", # uhhhh FIX should be s(:self)
           s(:call, s(:lvar, :self), :method, nil))

  add_test("call_arglist",
           s(:call, nil, :puts, s(:arglist, s(:lit, 42))))

  add_test("call_index",
           s(:call, s(:call, nil, :a, nil), :[], s(:arglist, s(:lit, 42))))

  add_test("case",
           s(:block,
             s(:lasgn, :var, s(:lit, 2)),
             s(:lasgn, :result, s(:str, "")),
             s(:if,
               s(:call, s(:lvar, :var), "===".intern,
                 s(:arglist, s(:lit, 1))),
               s(:block,
                 s(:call, nil, :puts, s(:arglist, s(:str, "something"))),
                 s(:lasgn, :result, s(:str, "red"))),
               s(:if,
                 s(:or,
                   s(:call, s(:lvar, :var), "===".intern,
                     s(:arglist, s(:lit, 2))),
                   s(:call, s(:lvar, :var), "===".intern,
                     s(:arglist, s(:lit, 3)))),
                 s(:lasgn, :result, s(:str, "yellow")),
                 s(:if,
                   s(:call, s(:lvar, :var), "===".intern,
                     s(:arglist, s(:lit, 4))),
                   nil,
                   s(:lasgn, :result, s(:str, "green"))))),
             s(:if,
               s(:call, s(:lvar, :result), "===".intern,
                 s(:arglist, s(:str, "red"))),
               s(:lasgn, :var, s(:lit, 1)),
               s(:if,
                 s(:call, s(:lvar, :result), "===".intern,
                   s(:arglist, s(:str, "yellow"))),
                 s(:lasgn, :var, s(:lit, 2)),
                 s(:if,
                   s(:call, s(:lvar, :result), "===".intern,
                     s(:arglist, s(:str, "green"))),
                   s(:lasgn, :var, s(:lit, 3)),
                   nil)))))

  add_test("case_nested",
           s(:block,
             s(:lasgn, :var1, s(:lit, 1)),
             s(:lasgn, :var2, s(:lit, 2)),
             s(:lasgn, :result, s(:nil)),
             s(:if,
               s(:call, s(:lvar, :var1), :===, s(:arglist, s(:lit, 1))),
               s(:if,
                 s(:call, s(:lvar, :var2), :===, s(:arglist, s(:lit, 1))),
                 s(:lasgn, :result, s(:lit, 1)),
                 s(:if,
                   s(:call, s(:lvar, :var2), :===, s(:arglist, s(:lit, 2))),
                   s(:lasgn, :result, s(:lit, 2)),
                   s(:lasgn, :result, s(:lit, 3)))),
               s(:if,
                 s(:call, s(:lvar, :var1), :===, s(:arglist, s(:lit, 2))),
                 s(:if,
                   s(:call, s(:lvar, :var2), :===, s(:arglist, s(:lit, 1))),
                   s(:lasgn, :result, s(:lit, 4)),
                   s(:if,
                     s(:call, s(:lvar, :var2), :===, s(:arglist, s(:lit, 2))),
                     s(:lasgn, :result, s(:lit, 5)),
                     s(:lasgn, :result, s(:lit, 6)))),
                 s(:lasgn, :result, s(:lit, 7))))))

  add_test("case_no_expr",
           s(:if,
             s(:call, nil, :===, s(:arglist, s(:lit, 1))),
             s(:lit, :a),
             s(:if,
               s(:call, nil, :===, s(:arglist, s(:lit, 2))),
               s(:lit, :b),
               s(:lit, :c))))

  add_test("cdecl",
           s(:cdecl, :X, s(:lit, 42)))

  add_test("class_plain",
           s(:class, :X, nil,
             s(:scope,
               s(:block,
                 s(:call, nil, :puts,
                   s(:arglist,
                     s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))))),
                 s(:defn, :blah,
                   s(:args),
                   s(:scope,
                     s(:block,
                       s(:call, nil, :puts, s(:arglist, s(:str, "hello"))))))))))

  add_test("class_super_array",
           s(:class, :X, s(:const, :Array), s(:scope)))

  add_test("class_super_expr",
           s(:class, :X, s(:call, nil, :expr, nil), s(:scope)))

  add_test("class_super_object",
           s(:class, :X, s(:const, :Object), s(:scope)))

  add_test("colon2",
           s(:colon2, s(:const, :X), :Y))

  add_test("colon3",
           s(:colon3, :X))

  add_test("conditional1",
           s(:if,
             s(:call, s(:lit, 42), :==, s(:arglist, s(:lit, 0))),
             s(:return, s(:lit, 1)),
             nil))

  add_test("conditional2",
           s(:if,
             s(:call, s(:lit, 42),
               :==, s(:arglist, s(:lit, 0))),
             nil,
             s(:return, s(:lit, 2))))

  add_test("conditional3",
           s(:if,
             s(:call,
               s(:lit, 42),
               :==,
               s(:arglist, s(:lit, 0))),
             s(:return, s(:lit, 3)),
             s(:return, s(:lit, 4))))

  add_test("conditional4",
           s(:if,
             s(:call,
               s(:lit, 42),
               :==,
               s(:arglist, s(:lit, 0))),
             s(:return, s(:lit, 2)),
             s(:if,
               s(:call,
                 s(:lit, 42),
                 :<,
                 s(:arglist, s(:lit, 0))),
               s(:return, s(:lit, 3)),
               s(:return, s(:lit, 4)))))

  add_test("conditional5",
           s(:if, s(:true),
             nil,
             s(:if, s(:false), s(:return), nil)))

  add_test("const",
           s(:const, :X))

  add_test("cvar",
           s(:cvar, :@@x))

  add_test("cvasgn",
           s(:defn, :x,
             s(:args),
             s(:scope, s(:block, s(:cvasgn, :@@blah, s(:lit, 1))))))

  add_test("cvdecl",
           s(:class, :X, nil, s(:scope, s(:cvdecl, :@@blah, s(:lit, 1)))))

  add_test("dasgn",
           s(:iter,
             s(:call, s(:call, nil, :a, nil), :each, nil),
             s(:dasgn_curr, :x),
             s(:iter,
               s(:call, s(:call, nil, :b, nil), :each, nil),
               s(:dasgn_curr, :y),
               s(:dasgn, :x,
                 s(:call, s(:dvar, :x), :+, s(:arglist, s(:lit, 1)))))))

  add_test("dasgn_curr",
           s(:iter,
             s(:call, s(:call, nil, :data, nil), :each, nil),
             s(:masgn, s(:array, s(:dasgn_curr, :x), s(:dasgn_curr, :y))),
             s(:block,
               s(:dasgn_curr, :a, s(:dasgn_curr, :b)),
               s(:dasgn_curr, :a, s(:lit, 1)),
               s(:dasgn_curr, :b, s(:dvar, :a)),
               s(:dasgn_curr, :b, s(:dasgn_curr, :a, s(:dvar, :x))))))

  add_test("defined",
           s(:defined, s(:gvar, :$x)))

  add_test("defn_args",
           s(:defn, :x,
             s(:args, :a, :b, :"*c"),
             s(:scope,
               s(:block,
                 s(:if, s(:call, s(:lvar, :b), :nil?),
                   s(:lasgn, :b, s(:lit, 42)),
                   nil),
                 s(:block_arg, :d),
                 s(:call, nil, :p,
                   s(:arglist,
                     s(:lvar, :a), s(:lvar, :b), s(:lvar, :c), s(:lvar, :d)))))))

  add_test("defn_empty",
           s(:defn, :empty,
             s(:args), s(:scope, s(:block, s(:nil)))))

  add_test("defn_is_something",
           s(:defn, :something?,
             s(:args), s(:scope, s(:block, s(:nil)))))

  add_test("defn_or",
           s(:defn, :|,
             s(:args, :o), s(:scope, s(:block, s(:nil)))))

  add_test("defn_rescue",
           s(:defn, :blah,
             s(:args),
             s(:scope,
               s(:block,
                 s(:rescue,
                   s(:lit, 42),
                   s(:resbody, nil, s(:lit, 24)))))))

  add_test("defn_zarray",
           s(:defn,
             :zarray,
             s(:args),
             s(:scope,
               s(:block, s(:lasgn, :a, s(:array)), s(:return, s(:lvar, :a))))))

  add_test("defs",
           s(:defs,
             s(:lvar, :self),
             :x,
             s(:scope,
               s(:block,
                 s(:args, :y),
                 s(:call, s(:lvar, :y), :+, s(:arglist, s(:lit, 1)))))))

  add_test("dmethod",
           s(:defn,
             :dmethod_added,
             s(:args, :x),
             s(:scope,
               s(:block,
                 s(:call, s(:lvar, :x), :+, s(:arglist, s(:lit, 1)))))))

  add_test("dot2",
           s(:dot2, s(:call, nil, :a, nil), s(:call, nil, :b, nil)))

  add_test("dot3",
           s(:dot3, s(:call, nil, :a, nil), s(:call, nil, :b, nil)))

  add_test("dregx",
           s(:dregx, "x",
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))), s(:str, "y")))

  add_test("dregx_once",
           s(:dregx_once,
             "x",
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))),
             s(:str, "y")))

  add_test("dstr",
           s(:block,
             s(:lasgn, :argl, s(:lit, 1)),
             s(:dstr, "x", s(:lvar, :argl), s(:str, "y"))))

  add_test("dsym",
           s(:dsym, "x",
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))), s(:str, "y")))

  add_test("dxstr",
           s(:block,
             s(:lasgn, :t, s(:lit, 5)), s(:dxstr, "touch ", s(:lvar, :t))))

  add_test("ensure",
               s(:begin,
                 s(:ensure,
                   s(:rescue,
                     s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))),
                     s(:resbody,
                       s(:array, s(:const, :SyntaxError)),
                       s(:block, s(:lasgn, :e1, s(:gvar, :$!)), s(:lit, 2)),
                       s(:resbody,
                         s(:array, s(:const, :Exception)),
                         s(:block, s(:lasgn, :e2, s(:gvar, :$!)), s(:lit, 3)))),
                     s(:lit, 4)),
                   s(:lit, 5))))

  add_test("false",
           s(:false))

  add_test("fbody",
           s(:defn,
             :an_alias,
             s(:args, :x),
             s(:scope,
               s(:block,
                 s(:call, s(:lvar, :x), :+, s(:arglist, s(:lit, 1)))))))

  add_test("fcall",
           s(:call, nil, :p, s(:arglist, s(:lit, 4))))

  add_test("flip2",
           s(:lasgn,
             :x,
             s(:if,
               s(:flip2,
                 s(:call,
                   s(:call, s(:call, nil, :i, nil), :%, s(:arglist, s(:lit, 4))),
                   :==,
                   s(:arglist, s(:lit, 0))),
                 s(:call,
                   s(:call, s(:call, nil, :i, nil), :%, s(:arglist, s(:lit, 3))),
                   :==,
                   s(:arglist, s(:lit, 0)))),
               s(:call, nil, :i, nil),
               s(:nil))))

  add_test("flip3",
           s(:lasgn,
             :x,
             s(:if,
               s(:flip3,
                 s(:call,
                   s(:call, s(:call, nil, :i, nil), :%, s(:arglist, s(:lit, 4))),
                   :==,
                   s(:arglist, s(:lit, 0))),
                 s(:call,
                   s(:call, s(:call, nil, :i, nil), :%, s(:arglist, s(:lit, 3))),
                   :==,
                   s(:arglist, s(:lit, 0)))),
               s(:call, nil, :i, nil),
               s(:nil))))

  add_test("for",
           s(:for,
             s(:call, nil, :ary, nil),
             s(:lasgn, :o),
             s(:call, nil, :puts, s(:arglist, s(:lvar, :o)))))

  add_test("gasgn",
           s(:gasgn, :$x, s(:lit, 42)))

  add_test("global",
           s(:gvar, "$stderr".intern))

  add_test("gvar",
           s(:gvar, :$x))

  add_test("hash",
           s(:hash, s(:lit, 1), s(:lit, 2), s(:lit, 3), s(:lit, 4)))

  add_test("iasgn",
           s(:iasgn, :@a, s(:lit, 4)))

  add_test("iteration1",
           s(:iter, s(:call, nil, :loop, nil), s(:dasgn_curr, :temp_1), nil))

  add_test("iteration2",
           s(:block,
             s(:lasgn, :array, s(:array, s(:lit, 1), s(:lit, 2), s(:lit, 3))),
             s(:iter,
               s(:call, s(:lvar, :array), :each, nil),
               s(:dasgn_curr, :x),
               s(:call, nil, :puts,
                 s(:arglist, s(:call, s(:dvar, :x), :to_s, nil))))))

  add_test("iteration3",
           s(:dummy,
             s(:lasgn, :n, s(:lit, 1)),
             s(:while,
               s(:call, s(:lvar, :n), :<=, s(:arglist, s(:lit, 3))),
               s(:block,
                 s(:call, nil, :puts,
                   s(:arglist, s(:call, s(:lvar, :n), :to_s, nil))),
                 s(:lasgn, :n,
                   s(:call, s(:lvar, :n), :+, s(:arglist, s(:lit, 1))))),
               true)))

  add_test("iteration4",
           s(:dummy,
             s(:lasgn, :n, s(:lit, 3)),
             s(:while,
               s(:call, s(:lvar, :n), :>=, s(:arglist, s(:lit, 1))),
               s(:block,
                 s(:call,
                   nil,
                   :puts,
                   s(:arglist, s(:call, s(:lvar, :n), :to_s, nil))),
                 s(:lasgn, :n,
                   s(:call, s(:lvar, :n),
                     :-,
                     s(:arglist, s(:lit, 1))))), true)))

  add_test("iteration5",
           s(:block,
             s(:lasgn, :argl, s(:lit, 10)),
             s(:while,
               s(:call, s(:lvar, :argl), :>=, s(:arglist, s(:lit, 1))),
               s(:block,
                 s(:call, nil, :puts,
                   s(:arglist, s(:str, "hello"))),
                 s(:lasgn, :argl, s(:call, s(:lvar, :argl),
                                 :-, s(:arglist, s(:lit, 1))))), true)))

  add_test("iteration6",
           s(:block,
             s(:lasgn, :array1, s(:array, s(:lit, 1), s(:lit, 2), s(:lit, 3))),
             s(:lasgn, :array2,
               s(:array, s(:lit, 4), s(:lit, 5), s(:lit, 6), s(:lit, 7))),
             s(:iter,
               s(:call, s(:lvar, :array1), :each, nil),
               s(:dasgn_curr, :x),
               s(:iter,
                 s(:call, s(:lvar, :array2), :each, nil),
                 s(:dasgn_curr, :y),
                 s(:block,
                   s(:call, nil, :puts,
                     s(:arglist, s(:call, s(:dvar, :x), :to_s, nil))),
                   s(:call, nil, :puts,
                     s(:arglist, s(:call, s(:dvar, :y), :to_s, nil))))))))

  add_test("ivar",
           s(:defn,
             :reader,
             s(:args),
             s(:scope, s(:block, s(:return, s(:ivar, :@reader))))))

  add_test("lasgn_array",
           s(:lasgn, :var,
             s(:array,
               s(:str, "foo"),
               s(:str, "bar"))))

  add_test("lasgn_call",
           s(:lasgn, :c, s(:call, s(:lit, 2), :+, s(:arglist, s(:lit, 3)))))

  add_test("lit_bool_false",
           s(:false))

  add_test("lit_bool_true",
           s(:true))

  add_test("lit_float",
           s(:lit, 1.1))

  add_test("lit_long",
           s(:lit, 1))

  add_test("lit_range2",
           s(:lit, 1..10))

  add_test("lit_range3",
           s(:lit, 1...10))

  add_test("lit_regexp",
           s(:lit, /x/))

  add_test("lit_str",
           s(:str, "x"))

  add_test("lit_sym",
           s(:lit, :x))

  add_test("masgn",
           s(:masgn,
             s(:array, s(:lasgn, :a), s(:lasgn, :b)),
             s(:array, s(:call, nil, :c, nil), s(:call, nil, :d, nil))))

  add_test("masgn_iasgn",
           s(:masgn,
             s(:array, s(:lasgn, :a), s(:iasgn, :@b)),
             s(:array, s(:call, nil, :c, nil), s(:call, nil, :d, nil))))

  add_test("match",
           s(:if, s(:match, s(:lit, /x/)), s(:lit, 1), nil))

  add_test("match2",
           s(:match2, s(:lit, /x/), s(:str, "blah")))

  add_test("match3",
           s(:match3, s(:lit, /x/), s(:str, "blah")))

  add_test("module",
           s(:module, :X,
             s(:scope,
               s(:defn, :y, s(:args), s(:scope, s(:block, s(:nil)))))))

  add_test("next",
           s(:iter,
             s(:call, nil, :loop, nil),
             s(:dasgn_curr, :temp_1),
             s(:if, s(:false), s(:next), nil)))

  add_test("not",
           s(:not, s(:true)))

  add_test("nth_ref",
           s(:nth_ref, 1))

  add_test("op_asgn1",
           s(:block,
             s(:lasgn, :b, s(:array)),
             s(:op_asgn1, s(:lvar, :b),
               s(:array, s(:lit, 1)), "||".intern, s(:lit, 10)),
             s(:op_asgn1, s(:lvar, :b),
               s(:array, s(:lit, 2)), "&&".intern, s(:lit, 11)),
             s(:op_asgn1, s(:lvar, :b),
               s(:array, s(:lit, 3)), "+".intern, s(:lit, 12))))

  add_test("op_asgn2",
           s(:block,
             s(:lasgn, :s,
               s(:call, s(:const, :Struct), :new,
                 s(:arglist, s(:lit, :var)))),
             s(:lasgn, :c,
               s(:call, s(:lvar, :s), :new, s(:arglist, s(:nil)))),
             s(:op_asgn2, s(:lvar, :c), :var=, "||".intern, s(:lit, 20)),
             s(:op_asgn2, s(:lvar, :c), :var=, "&&".intern, s(:lit, 21)),
             s(:op_asgn2, s(:lvar, :c), :var=, "+".intern, s(:lit, 22)),
             s(:op_asgn2,
               s(:call, s(:call, s(:lvar, :c), :d, nil), :e, nil),
               :f=, "||".intern, s(:lit, 42))))

  add_test("op_asgn_and",
           s(:block,
             s(:lasgn, :a, s(:lit, 0)),
             s(:op_asgn_and, s(:lvar, :a), s(:lasgn, :a, s(:lit, 2)))))

  add_test("op_asgn_or",
           s(:block,
             s(:lasgn, :a, s(:lit, 0)),
             s(:op_asgn_or, s(:lvar, :a), s(:lasgn, :a, s(:lit, 1)))))

  add_test("or",
           s(:or, s(:call, nil, :a, nil), s(:call, nil, :b, nil)))

  add_test("postexe", # question that variable
           s(:iter, s(:postexe), s(:dasgn_curr, :temp_1), s(:lit, 1)))

  add_test("proc_args",
           s(:iter,
             s(:call, nil, :proc, nil),
             s(:dasgn_curr, :x),
             s(:call, s(:dvar, :x), :+, s(:arglist, s(:lit, 1)))))

  add_test("proc_no_args", # TODO: verify that this dasgn_curr is correct
           s(:iter,
             s(:call, nil, :proc, nil),
             s(:dasgn_curr, :temp_1),
             s(:call, s(:call, nil, :x, nil), :+, s(:arglist, s(:lit, 1)))))

  add_test("redo",
           s(:iter,
             s(:call, nil, :loop, nil),
             s(:dasgn_curr, :temp_1),
             s(:if, s(:false), s(:redo), nil)))

  add_test("rescue",
           s(:rescue,
             s(:call, nil, :blah, nil),
             s(:resbody, nil, s(:nil))))

  add_test("rescue_block_body",
           s(:begin,
             s(:rescue,
               s(:call, nil, :blah, nil), s(:resbody, nil, s(:nil)))))

  add_test("rescue_block_nada",
           s(:begin,
             s(:rescue,
               s(:call, nil, :blah, nil), s(:resbody, nil))))

  add_test("rescue_exceptions",
           s(:begin,
             s(:rescue,
               s(:call, nil, :blah, nil),
               s(:resbody,
                 s(:array, s(:const, :RuntimeError)),
                 s(:lasgn, :r, s(:gvar, :$!))))))

  add_test("retry",
           s(:retry))

  add_test("sclass",
           s(:sclass, s(:lvar, :self), s(:scope, s(:lit, 42))))

  add_test("splat",
           s(:call, nil, :a, s(:arglist, s(:call, nil, :b, nil))))

  add_test("super",
           s(:defn, :x,
             s(:args), s(:scope, s(:block, s(:super, s(:array, s(:lit, 4)))))))

  add_test("super_multi",
           s(:defn, :x,
             s(:args),
             s(:scope,
               s(:block,
                 s(:super, s(:array, s(:lit, 4), s(:lit, 2), s(:lit, 1)))))))

  add_test("svalue",
           s(:lasgn, :a, s(:svalue, s(:splat, s(:call, nil, :b, nil)))))

  add_test("to_ary",
           s(:masgn,
             s(:array, s(:lasgn, :a), s(:lasgn, :b)),
             s(:to_ary, s(:call, nil, :c, nil))))

  add_test("true",
           s(:true))

  add_test("undef",
           s(:undef, s(:lit, :x)))

  add_test("undef_multi",
           s(:block,
             s(:undef, s(:lit, :x)),
             s(:undef, s(:lit, :y)),
             s(:undef, s(:lit, :z))))

  add_test("until_post",
           s(:while,
             s(:not, s(:false)),
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))),
             false))

  add_test("until_pre",
           s(:while,
             s(:not, s(:false)),
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))),
             true))

  add_test("valias",
           s(:valias, :$y, :$x))

  add_test("vcall",
           s(:call, nil, :method, nil))

  add_test("while_post",
           s(:while, s(:false),
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))), false))

  add_test("while_pre",
           s(:while, s(:false),
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))), true))

  add_test("while_pre_nil",
           s(:while, s(:false), nil, true))

  add_test("xstr",
           s(:xstr, "touch 5"))

  add_test("yield",
           s(:yield))

  add_test("yield_arg",
           s(:yield, s(:lit, 42)))

  add_test("yield_args",
           s(:yield, s(:array, s(:lit, 42), s(:lit, 24))))

  add_test("zarray",
           s(:lasgn, :a, s(:array)))

  add_test("zsuper",
           s(:defn, :x, s(:args), s(:scope, s(:block, s(:zsuper)))))
end

if $0 == __FILE__
  require 'test/unit'
  ARGV << '-t' << "Test#{ParseTreeTestCase.testcase_order.last}"
end
