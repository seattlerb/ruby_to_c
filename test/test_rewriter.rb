#!/usr/local/bin/ruby -w

$TESTING = true

require 'test/unit' if $0 == __FILE__
require 'rewriter'
require 'r2ctestcase'
require 'pt_testcase'

ParseTreeTestCase.testcase_order << "Rewriter"

class TestRewriter < ParseTreeTestCase
  def setup
    super
    @processor = Rewriter.new
  end

  def self.add_test name, data, klass = self.name[4..-1]
    sexp = Sexp.from_array(testcases[name]["ParseTree"])
    if data == :same then
      super(name, sexp, klass)
    else
      warn "add_test(#{name.inspect}, :same)" if data == sexp
      super(name, Sexp.from_array(data), klass)
    end
  end

  add_test("alias",
           s(:class, :X, nil, s(:scope, s(:alias, s(:lit, :y), s(:lit, :x)))))

  add_test("alias_ugh", :same)

  add_test("and",
           s(:and,
             s(:call, nil, :a, s(:arglist)),
             s(:call, nil, :b, s(:arglist))))

  add_test("argscat_inside",
           s(:lasgn, :a,
             s(:argscat,
               s(:array, s(:call, nil, :b, s(:arglist))),
               s(:call, nil, :c, s(:arglist)))))

  add_test("argscat_svalue",
           s(:lasgn,
             :a,
             s(:svalue,
               s(:argscat,
                 s(:array, s(:call, nil, :b, s(:arglist)), s(:call, nil, :c, s(:arglist))),
                 s(:call, nil, :d, s(:arglist))))))

  add_test("argspush",
           s(:attrasgn,
             s(:call, nil, :a, s(:arglist)),
             :[]=,
             s(:argspush,
               s(:splat, s(:call, nil, :b, s(:arglist))),
               s(:call, nil, :c, s(:arglist)))))

  add_test("array",
           s(:array, s(:lit, 1), s(:lit, :b), s(:str, "c")))

  add_test("array_pct_W", :same)

  add_test("attrasgn",
           s(:block,
             s(:lasgn, :y, s(:lit, 0)),
             s(:attrasgn, s(:lit, 42), :method=, s(:arglist, s(:lvar, :y)))))

  add_test("attrasgn_index_equals",
           s(:attrasgn, s(:call, nil, :a, s(:arglist)), :[]=,
             s(:arglist, s(:lit, 42), s(:lit, 24))))

  add_test("attrasgn_index_equals_space", :same)

  add_test("attrset",
           s(:defn, :writer=,
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

  add_test("begin_def",
           s(:defn, :m, s(:args), s(:scope, s(:block, s(:nil)))))

  add_test("begin_rescue_ensure", :same)

  add_test("begin_rescue_twice", :same)

  add_test("block_lasgn",
           s(:lasgn, :x,
             s(:block,
               s(:lasgn, :y, s(:lit, 1)),
               s(:call, s(:lvar, :y), :+, s(:arglist, s(:lit, 2))))))

  add_test("block_mystery_block",
           s(:iter,
             s(:call, nil, :a, s(:arglist, s(:call, nil, :b, s(:arglist)))),
             nil,
             s(:if,
               s(:call, nil, :b, s(:arglist)),
               s(:true),
               s(:block,
                 s(:lasgn, :c, s(:false)),
                 s(:iter,
                   s(:call, nil, :d, s(:arglist)),
                   s(:lasgn, :x),
                   s(:lasgn, :c, s(:true))),
                 s(:lvar, :c)))))

  add_test("block_pass_args_and_splat",
           s(:defn, :blah,
             s(:args, :"*args",
                 s(:block_arg, :block)),
             s(:scope,
               s(:block,
                 s(:block_pass,
                   s(:lvar, :block),
                   s(:call, nil, :other,
                     s(:argscat, s(:array, s(:lit, 42)), s(:lvar, :args))))))))

  add_test("block_pass_call_0",
           s(:block_pass,
             s(:call, nil, :c, s(:arglist)),
             s(:call, s(:call, nil, :a, s(:arglist)), :b, s(:arglist))))

  add_test("block_pass_call_1",
           s(:block_pass,
             s(:call, nil, :c, s(:arglist)),
             s(:call, s(:call, nil, :a, s(:arglist)), :b, s(:arglist, s(:lit, 4)))))

  add_test("block_pass_call_n",
           s(:block_pass,
             s(:call, nil, :c, s(:arglist)),
             s(:call, s(:call, nil, :a, s(:arglist)), :b,
               s(:arglist, s(:lit, 1), s(:lit, 2), s(:lit, 3)))))

  add_test("block_pass_fcall_0",
           s(:block_pass, s(:call, nil, :b, s(:arglist)), s(:call, nil, :a, s(:arglist))))

  add_test("block_pass_fcall_1",
           s(:block_pass,
             s(:call, nil, :b, s(:arglist)),
             s(:call, nil, :a, s(:arglist, s(:lit, 4)))))

  add_test("block_pass_fcall_n",
           s(:block_pass,
             s(:call, nil, :b, s(:arglist)),
             s(:call, nil, :a,
               s(:arglist, s(:lit, 1), s(:lit, 2), s(:lit, 3)))))

  add_test("block_pass_omgwtf",
           s(:block_pass,
             s(:iter,
               s(:call, s(:const, :Proc), :new, s(:arglist)),
               s(:masgn, s(:lasgn, :args)),
               s(:nil)),
             s(:call, nil, :define_attr_method,
               s(:arglist, s(:lit, :x), s(:lit, :sequence_name)))))

  add_test("block_pass_splat",
           s(:defn, :blah,
             s(:args, :"*args", s(:block_arg, :block)),
             s(:scope,
               s(:block,
                 s(:block_pass,
                   s(:lvar, :block),
                   s(:call, nil, :other,
                     s(:splat, s(:lvar, :args))))))))

  add_test("block_pass_thingy",
           s(:block_pass,
             s(:call, nil, :block, s(:arglist)),
             s(:call, s(:call, nil, :r, s(:arglist)), :read_body,
               s(:arglist, s(:call, nil, :dest, s(:arglist))))))

  add_test("block_stmt_after",
           s(:defn, :f,
             s(:args),
             s(:scope,
               s(:block,
                 s(:rescue, s(:call, nil, :b, s(:arglist)), s(:resbody, s(:array), s(:call, nil, :c, s(:arglist)))),
                 s(:call, nil, :d, s(:arglist))))))

  add_test("block_stmt_before",
           s(:defn, :f,
             s(:args),
             s(:scope,
               s(:block,
                 s(:call, nil, :a, s(:arglist)),
                 s(:begin,
                   s(:rescue, s(:call, nil, :b, s(:arglist)),
                     s(:resbody, s(:array), s(:call, nil, :c, s(:arglist)))))))))

  add_test("block_stmt_both",
           s(:defn, :f,
             s(:args),
             s(:scope,
               s(:block,
                 s(:call, nil, :a, s(:arglist)),
                 s(:rescue, s(:call, nil, :b, s(:arglist)), s(:resbody, s(:array), s(:call, nil, :c, s(:arglist)))),
                 s(:call, nil, :d, s(:arglist))))))

  add_test("bmethod",
           s(:defn, :unsplatted,
             s(:args, :x),
             s(:scope,
               s(:block, s(:call, s(:lvar, :x), :+, s(:arglist, s(:lit, 1)))))))

  add_test("bmethod_noargs",
           s(:defn, :bmethod_noargs,
             s(:args),
             s(:scope,
               s(:block,
                 s(:call, s(:call, nil, :x, s(:arglist)), :"+",
                   s(:arglist, s(:lit, 1)))))))

  add_test("bmethod_splat",
           s(:defn, :splatted,
             s(:args, :"*args"),
             s(:scope,
               s(:block,
                 s(:lasgn, :y, s(:call, s(:lvar, :args), :first, s(:arglist))),
                 s(:call, s(:lvar, :y), :+, s(:arglist, s(:lit, 42)))))))

  add_test("break",
           s(:iter,
             s(:call, nil, :loop, s(:arglist)),
             nil,
             s(:if, s(:true), s(:break), nil)))

  add_test("break_arg",
           s(:iter,
             s(:call, nil, :loop, s(:arglist)),
             nil,
             s(:if, s(:true), s(:break, s(:lit, 42)), nil)))

  add_test("call",
           s(:call, s(:self), :method, s(:arglist)))

  add_test("call_arglist",
           s(:call, s(:call, nil, :o, s(:arglist)), :puts, s(:arglist, s(:lit, 42))))

  add_test("call_arglist_hash",
           s(:call,
             s(:call, nil, :o, s(:arglist)), :m,
             s(:arglist,
               s(:hash, s(:lit, :a), s(:lit, 1), s(:lit, :b), s(:lit, 2)))))

  add_test("call_arglist_norm_hash",
           s(:call,
             s(:call, nil, :o, s(:arglist)), :m,
             s(:arglist,
               s(:lit, 42),
               s(:hash, s(:lit, :a), s(:lit, 1), s(:lit, :b), s(:lit, 2)))))

  add_test("call_arglist_norm_hash_splat",
           s(:call,
             s(:call, nil, :o, s(:arglist)), :m,
             s(:argscat,
               s(:array,
                 s(:lit, 42),
                 s(:hash, s(:lit, :a), s(:lit, 1), s(:lit, :b), s(:lit, 2))),
               s(:call, nil, :c, s(:arglist)))))

  add_test("call_command",
           s(:call, s(:lit, 1), :b, s(:arglist, s(:call, nil, :c, s(:arglist)))))

  add_test("call_expr",
           s(:call,
             s(:lasgn, :v, s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1)))),
             :zero?, s(:arglist)))

  add_test("call_index",
           s(:block,
             s(:lasgn, :a, s(:zarray)),
           s(:call, s(:lvar, :a), :[], s(:arglist, s(:lit, 42)))))

  add_test("call_index_no_args",
           s(:call, s(:call, nil, :a, s(:arglist)), :[], s(:arglist)))

  add_test("call_index_space", :same)

  add_test("call_unary_neg",
           s(:call,
             s(:call, s(:lit, 2), :**, s(:arglist, s(:lit, 31))), :-@, s(:arglist)))

  add_test("case", :same)

  add_test("case_nested",
           s(:block,
             s(:lasgn, :var1, s(:lit, 1)),
             s(:lasgn, :var2, s(:lit, 2)),
             s(:lasgn, :result, s(:nil)),
             s(:case,
               s(:lvar, :var1),
               s(:when,
                 s(:array, s(:lit, 1)),
                 s(:case,
                   s(:lvar, :var2),
                   s(:when, s(:array, s(:lit, 1)), s(:lasgn, :result, s(:lit, 1))),
                   s(:when, s(:array, s(:lit, 2)), s(:lasgn, :result, s(:lit, 2))),
                   s(:lasgn, :result, s(:lit, 3)))),
               s(:when,
                 s(:array, s(:lit, 2)),
                 s(:case,
                   s(:lvar, :var2),
                   s(:when, s(:array, s(:lit, 1)), s(:lasgn, :result, s(:lit, 4))),
                   s(:when, s(:array, s(:lit, 2)), s(:lasgn, :result, s(:lit, 5))),
                   s(:lasgn, :result, s(:lit, 6)))),
               s(:lasgn, :result, s(:lit, 7)))))

  add_test("case_nested_inner_no_expr", :same)

  add_test("case_no_expr",
           s(:case,
             nil,
             s(:when,
               s(:array,
                 s(:call, s(:call, nil, :a, s(:arglist)), :==,
                   s(:arglist, s(:lit, 1)))),
               s(:lit, :a)),
             s(:when,
               s(:array,
                 s(:call, s(:call, nil, :a, s(:arglist)), :==,
                   s(:arglist, s(:lit, 2)))),
               s(:lit, :b)),
             s(:lit, :c)))

  add_test("case_splat", :same)

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

  add_test("class_scoped", :same)
  add_test("class_scoped3", :same)

  add_test("class_super_array",
           s(:class, :X, s(:const, :Array), s(:scope)))

  add_test("class_super_expr",
           s(:class, :X, s(:call, nil, :expr, s(:arglist)), s(:scope)))

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

  add_test("conditional_post_if",
           s(:if, s(:call, nil, :b, s(:arglist)), s(:call, nil, :a, s(:arglist)), nil))

  add_test("conditional_post_if_not",
           s(:if, s(:call, nil, :b, s(:arglist)), nil, s(:call, nil, :a, s(:arglist))))

  add_test("conditional_post_unless",
           s(:if, s(:call, nil, :b, s(:arglist)), nil, s(:call, nil, :a, s(:arglist))))

  add_test("conditional_post_unless_not",
           s(:if, s(:call, nil, :b, s(:arglist)), s(:call, nil, :a, s(:arglist)), nil))

  add_test("conditional_pre_if",
           s(:if, s(:call, nil, :b, s(:arglist)), s(:call, nil, :a, s(:arglist)), nil))

  add_test("conditional_pre_if_not",
           s(:if, s(:call, nil, :b, s(:arglist)), nil, s(:call, nil, :a, s(:arglist))))

  add_test("conditional_pre_unless",
           s(:if, s(:call, nil, :b, s(:arglist)), nil, s(:call, nil, :a, s(:arglist))))

  add_test("conditional_pre_unless_not",
           s(:if, s(:call, nil, :b, s(:arglist)), s(:call, nil, :a, s(:arglist)), nil))

  add_test("const",
           s(:const, :X))

  add_test("constX", :same)
  add_test("constY", :same)
  add_test("constZ", :same)

  add_test("cvar",
           s(:cvar, :@@x))

  add_test("cvasgn",
           s(:defn, :x,
             s(:args),
             s(:scope, s(:block, s(:cvasgn, :@@blah, s(:lit, 1))))))

  add_test("cvasgn_cls_method",
           s(:defs, s(:self), :quiet_mode=,
             s(:args, :boolean),
             s(:scope,
               s(:block,
                 s(:cvasgn, :@@quiet_mode, s(:lvar, :boolean))))))

  add_test("cvdecl",
           s(:class, :X, nil, s(:scope, s(:cvdecl, :@@blah, s(:lit, 1)))))

  add_test("dasgn_0",
           s(:iter,
             s(:call, s(:call, nil, :a, s(:arglist)), :each, s(:arglist)),
             s(:lasgn, :x),
             s(:if, s(:true),
               s(:iter,
                 s(:call, s(:call, nil, :b, s(:arglist)), :each, s(:arglist)),
                 s(:lasgn, :y),
                 s(:lasgn, :x,
                   s(:call, s(:lvar, :x), :+, s(:arglist, s(:lit, 1))))),
               nil)))

  add_test("dasgn_1",
           s(:iter,
             s(:call, s(:call, nil, :a, s(:arglist)), :each, s(:arglist)),
             s(:lasgn, :x),
             s(:if, s(:true),
               s(:iter,
                 s(:call, s(:call, nil, :b, s(:arglist)), :each, s(:arglist)),
                 s(:lasgn, :y),
                 s(:lasgn, :c,
                   s(:call, s(:lvar, :c), :+, s(:arglist, s(:lit, 1))))),
               nil)))

  add_test("dasgn_2",
           s(:iter,
             s(:call, s(:call, nil, :a, s(:arglist)), :each, s(:arglist)),
             s(:lasgn, :x),
             s(:if, s(:true),
               s(:block,
                 s(:lasgn, :c, s(:lit, 0)),
                 s(:iter,
                   s(:call, s(:call, nil, :b, s(:arglist)), :each, s(:arglist)),
                   s(:lasgn, :y),
                   s(:lasgn, :c,
                     s(:call, s(:lvar, :c), :+, s(:arglist, s(:lit, 1)))))),
               nil)))

  add_test("dasgn_curr",
           s(:iter,
             s(:call, s(:call, nil, :data, s(:arglist)), :each, s(:arglist)),
             s(:masgn, s(:array, s(:lasgn, :x), s(:lasgn, :y))),
             s(:block,
               s(:lasgn, :a, s(:lit, 1)),
               s(:lasgn, :b, s(:lvar, :a)),
               s(:lasgn, :b, s(:lasgn, :a, s(:lvar, :x))))))

  add_test("dasgn_icky",
           s(:iter,
             s(:call, nil, :a, s(:arglist)),
             nil,
             s(:block,
               s(:lasgn, :v, s(:nil)),
               s(:iter,
                 s(:call, nil, :assert_block,
                   s(:arglist, s(:call, nil, :full_message, s(:arglist)))),
                 nil,
                 s(:begin,
                   s(:rescue,
                     s(:yield),
                     s(:resbody,
                       s(:array,
                         s(:const, :Exception),
                         s(:lasgn, :v, s(:gvar, :$!))),
                       s(:block, s(:break)))))))))

  add_test("dasgn_mixed",
           s(:block,
             s(:lasgn, :t, s(:lit, 0)),
             s(:iter,
               s(:call, s(:call, nil, :ns, s(:arglist)), :each, s(:arglist)),
               s(:lasgn, :n),
               s(:lasgn, :t,
                 s(:call, s(:lvar, :t), :+, s(:arglist, s(:lvar, :n)))))))

  add_test("defined",
           s(:defined, s(:gvar, :$x)))

  add_test("defn_args_mand_opt_block",
           s(:defn, :x,
             s(:args, :a, :b,
               s(:block, s(:lasgn, :b, s(:lit, 42))),
               s(:block_arg, :d)),
             s(:scope,
               s(:block,
                 s(:call, nil, :p,
                   s(:arglist, s(:lvar, :a), s(:lvar, :b), s(:lvar, :d)))))))

  add_test("defn_args_mand_opt_splat",
           s(:defn, :x,
             s(:args, :a, :b, :"*c",
               s(:block, s(:lasgn, :b, s(:lit, 42)))),
             s(:scope,
               s(:block,
                 s(:call, nil, :p,
                   s(:arglist, s(:lvar, :a), s(:lvar, :b), s(:lvar, :c)))))))

  add_test("defn_args_mand_opt_splat_block",
           s(:defn, :x,
             s(:args, :a, :b, :"*c",
               s(:block, s(:lasgn, :b, s(:lit, 42))),
               s(:block_arg, :d)),
             s(:scope,
               s(:block,
                 s(:call, nil, :p,
                   s(:arglist,
                     s(:lvar, :a), s(:lvar, :b), s(:lvar, :c), s(:lvar, :d)))))))

  add_test("defn_args_mand_opt_splat_no_name",
           s(:defn, :x,
             s(:args, :a, :b, :"*",
               s(:block, s(:lasgn, :b, s(:lit, 42)))),
             s(:scope,
               s(:block,
                 s(:call, nil, :p,
                   s(:arglist, s(:lvar, :a), s(:lvar, :b)))))))

  add_test("defn_args_opt_block",
           s(:defn, :x,
             s(:args, :b,
               s(:block, s(:lasgn, :b, s(:lit, 42))),
               s(:block_arg, :d)),
             s(:scope,
               s(:block,
                 s(:call, nil, :p,
                   s(:arglist, s(:lvar, :b), s(:lvar, :d)))))))

  add_test("defn_args_opt_splat_no_name",
           s(:defn, :x,
             s(:args, :b, :"*",
               s(:block, s(:lasgn, :b, s(:lit, 42)))),
             s(:scope,
               s(:block,
                 s(:call, nil, :p,
                   s(:arglist, s(:lvar, :b)))))))

  add_test("defn_empty",
           s(:defn, :empty,
             s(:args), s(:scope, s(:block, s(:nil)))))

  add_test("defn_empty_args",
           s(:defn, :empty,
             s(:args, :*),
             s(:scope, s(:block, s(:nil)))))

  add_test("defn_lvar_boundary",
           s(:block,
             s(:lasgn, :mes, s(:lit, 42)),
             s(:defn, :instantiate_all,
               s(:args),
               s(:scope,
                 s(:block,
                   s(:iter,
                     s(:call, s(:const, :Thread), :new, s(:arglist)),
                     nil,
                     s(:begin,
                       s(:rescue,
                         s(:resbody,
                           s(:array, s(:const, :RuntimeError), s(:lasgn, :mes, s(:gvar, :$!))),
                           s(:block,
                             s(:call, nil, :puts,
                               s(:arglist, s(:lvar, :mes)))))))))))))

  add_test("defn_optargs",
           s(:defn, :x,
             s(:args, :a, :"*args"),
             s(:scope,
               s(:block,
                 s(:call, nil, :p,
                   s(:arglist, s(:lvar, :a), s(:lvar, :args)))))))

  add_test("defn_or",
           s(:defn, :|,
             s(:args, :o), s(:scope, s(:block, s(:nil)))))

  add_test("defn_rescue",
           s(:defn, :eql?,
             s(:args, :resource),
             s(:scope,
               s(:block,
                 s(:rescue,
                   s(:call,
                     s(:call, s(:self), :uuid, s(:arglist)),
                     :==,
                     s(:arglist, s(:call, s(:lvar, :resource), :uuid, s(:arglist)))),
                   s(:resbody, s(:array), s(:false)))))))

  add_test("defn_something_eh",
           s(:defn, :something?,
             s(:args), s(:scope, s(:block, s(:nil)))))

  add_test("defn_splat_no_name",
           s(:defn, :x,
             s(:args, :a, :"*"),
             s(:scope,
               s(:block,
                 s(:call, nil, :p, s(:arglist, s(:lvar, :a)))))))

  add_test("defn_zarray",
           s(:defn, :zarray,
             s(:args),
             s(:scope,
               s(:block,
                 s(:lasgn, :a, s(:zarray)),
                 s(:return, s(:lvar, :a))))))

  add_test("defs",
           s(:defs, s(:self), :x,
             s(:args, :y),
             s(:scope,
               s(:block,
                 s(:call, s(:lvar, :y), :+, s(:arglist, s(:lit, 1)))))))

  add_test("defs_args_mand_opt_splat_block",
           s(:defs, s(:self), :x,
             s(:args, :a, :b, :"*c",
               s(:block, s(:lasgn, :b, s(:lit, 42))),
                 s(:block_arg, :d)),
             s(:scope,
               s(:block,
                 s(:call, s(:lvar, :a), :+, s(:arglist, s(:lvar, :b)))))))

  add_test("defs_empty",
           s(:defs, s(:self), :empty,
             s(:args),
             s(:scope, s(:block))))

  add_test("defs_empty_args",
           s(:defs, s(:self), :empty,
             s(:args, :*),
             s(:scope, s(:block))))

  add_test("dmethod",
           s(:defn, :dmethod_added,
             s(:args, :x),
             s(:scope,
               s(:block,
                 s(:call, s(:lvar, :x), :+, s(:arglist, s(:lit, 1)))))))

  add_test("dot2",
           s(:dot2, s(:call, nil, :a, s(:arglist)), s(:call, nil, :b, s(:arglist))))

  add_test("dot3",
           s(:dot3, s(:call, nil, :a, s(:arglist)), s(:call, nil, :b, s(:arglist))))

  add_test("dregx",
           s(:dregx, "x",
             s(:evstr, s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1)))),
             s(:str, "y")))

  add_test("dregx_interp", :same)
  add_test("dregx_n", :same)

  add_test("dregx_once",
           s(:dregx_once,
             "x",
             s(:evstr, s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1)))),
             s(:str, "y")))

  add_test("dregx_once_n_interp", :same)

  add_test("dstr",
           s(:block,
             s(:lasgn, :argl, s(:lit, 1)),
             s(:dstr, "x", s(:evstr, s(:lvar, :argl)), s(:str, "y"))))

  add_test("dstr_2",
           s(:block,
             s(:lasgn, :argl, s(:lit, 1)),
             s(:dstr,
               "x",
               s(:evstr, s(:call, s(:str, "%.2f"), :%,
                           s(:arglist, s(:lit, 3.14159)))),
               s(:str, "y"))))

  add_test("dstr_3",
           s(:block,
             s(:lasgn, :max, s(:lit, 2)),
             s(:lasgn, :argl, s(:lit, 1)),
             s(:dstr,
               "x",
               s(:evstr, s(:call,
                           s(:dstr, "%.",
                             s(:evstr, s(:lvar, :max)), s(:str, "f")),
                           :%, s(:arglist, s(:lit, 3.14159)))),
               s(:str, "y"))))

  add_test("dstr_concat", :same)

  add_test("dstr_heredoc_expand",
           s(:dstr, "  blah\n",
             s(:evstr, s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1)))),
             s(:str, "blah\n")))

  add_test("dstr_heredoc_windoze_sucks",
           s(:dstr,
             'def test_',
             s(:evstr, s(:call, nil, :action, s(:arglist))),
             s(:str, "_valid_feed\n")))

  add_test("dstr_heredoc_yet_again", :same)

  add_test("dstr_nest",
           s(:dstr, "before [",
             s(:evstr, s(:call, nil, :nest, s(:arglist))), s(:str, "] after")))

  add_test("dstr_str_lit_start",
           s(:dstr,
             "blah(string):",
             s(:evstr, s(:lit, 1)),
             s(:str, ": warning: "),
             s(:evstr, s(:call, s(:gvar, :$!), :message, s(:arglist))),
             s(:str, " ("),
             s(:evstr, s(:call, s(:gvar, :$!), :class, s(:arglist))),
             s(:str, ")")))

  add_test("dstr_the_revenge",
           s(:dstr,
             "before ",
             s(:evstr, s(:call, nil, :from, s(:arglist))),
             s(:str, " middle "),
             s(:evstr, s(:call, nil, :to, s(:arglist))),
             s(:str, " ("),
             s(:str, "(string)"),
             s(:str, ":"),
             s(:evstr, s(:lit, 1)),
             s(:str, ")")))

  add_test("dsym",
           s(:dsym, "x",
             s(:evstr, s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1)))),
             s(:str, "y")))

  add_test("dxstr",
           s(:block,
             s(:lasgn, :t, s(:lit, 5)),
             s(:dxstr, "touch ", s(:evstr, s(:lvar, :t)))))

  add_test("ensure",
               s(:begin,
                 s(:ensure,
                   s(:rescue,
                     s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))),
                     s(:resbody,
                       s(:array,
                         s(:const, :SyntaxError),
                         s(:lasgn, :e1, s(:gvar, :$!))),
                       s(:block, s(:lit, 2)),
                       s(:resbody,
                         s(:array,
                           s(:const, :Exception),
                           s(:lasgn, :e2, s(:gvar, :$!))),
                         s(:block, s(:lit, 3)))),
                     s(:lit, 4)),
                   s(:lit, 5))))

  add_test("false",
           s(:false))

  add_test("fbody",
           s(:defn, :an_alias,
             s(:args, :x),
             s(:scope,
               s(:block,
                 s(:call, s(:lvar, :x), :+, s(:arglist, s(:lit, 1)))))))

  add_test("fcall_arglist",
           s(:call, nil, :m, s(:arglist, s(:lit, 42))))

  add_test("fcall_arglist_hash",
           s(:call, nil, :m,
             s(:arglist,
               s(:hash, s(:lit, :a), s(:lit, 1), s(:lit, :b), s(:lit, 2)))))

  add_test("fcall_arglist_norm_hash",
           s(:call, nil, :m,
             s(:arglist,
               s(:lit, 42),
               s(:hash, s(:lit, :a), s(:lit, 1), s(:lit, :b), s(:lit, 2)))))

  add_test("fcall_arglist_norm_hash_splat",
           s(:call, nil, :m,
             s(:argscat,
               s(:array,
                 s(:lit, 42),
                 s(:hash, s(:lit, :a), s(:lit, 1), s(:lit, :b), s(:lit, 2))),
               s(:call, nil, :c, s(:arglist)))))

  add_test("fcall_block",
           s(:iter,
             s(:call, nil, :a, s(:arglist, s(:lit, :b))),
             nil,
             s(:lit, :c)))

  add_test("fcall_index_space", :same)

  add_test("fcall_keyword",
           s(:if, s(:call, nil, :block_given?, s(:arglist)), s(:lit, 42), nil))

  add_test("flip2",
           s(:lasgn,
             :x,
             s(:if,
               s(:flip2,
                 s(:call,
                   s(:call, s(:call, nil, :i, s(:arglist)), :%, s(:arglist, s(:lit, 4))),
                   :==,
                   s(:arglist, s(:lit, 0))),
                 s(:call,
                   s(:call, s(:call, nil, :i, s(:arglist)), :%, s(:arglist, s(:lit, 3))),
                   :==,
                   s(:arglist, s(:lit, 0)))),
               s(:call, nil, :i, s(:arglist)),
               s(:nil))))

  add_test("flip2_method",
           s(:if,
             s(:flip2,
               s(:lit, 1),
               s(:call, s(:lit, 2), :a?, s(:arglist, s(:call, nil, :b, s(:arglist))))),
             s(:nil),
             nil))

  add_test("flip3",
           s(:lasgn,
             :x,
             s(:if,
               s(:flip3,
                 s(:call,
                   s(:call, s(:call, nil, :i, s(:arglist)), :%, s(:arglist, s(:lit, 4))),
                   :==,
                   s(:arglist, s(:lit, 0))),
                 s(:call,
                   s(:call, s(:call, nil, :i, s(:arglist)), :%, s(:arglist, s(:lit, 3))),
                   :==,
                   s(:arglist, s(:lit, 0)))),
               s(:call, nil, :i, s(:arglist)),
               s(:nil))))

  add_test("for",
           s(:for,
             s(:call, nil, :ary, s(:arglist)),
             s(:lasgn, :o),
             s(:call, nil, :puts, s(:arglist, s(:lvar, :o)))))

  add_test("for_no_body",
           s(:for,
             s(:dot2, s(:lit, 0), s(:call, nil, :max, s(:arglist))),
             s(:lasgn, :i)))

  add_test("gasgn",
           s(:gasgn, :$x, s(:lit, 42)))

  add_test("global",
           s(:gvar, "$stderr".intern))

  add_test("gvar",
           s(:gvar, :$x))

  add_test("gvar_underscore", :same)
  add_test("gvar_underscore_blah", :same)

  add_test("hash",
           s(:hash, s(:lit, 1), s(:lit, 2), s(:lit, 3), s(:lit, 4)))

  add_test("hash_rescue", :same)

  add_test("iasgn",
           s(:iasgn, :@a, s(:lit, 4)))

  add_test("if_block_condition",
           s(:if,
             s(:block,
               s(:lasgn, :x, s(:lit, 5)),
               s(:call,
                 s(:lvar, :x),
                 :+,
                 s(:arglist, s(:lit, 1)))),
             s(:nil),
             nil))

  add_test("if_lasgn_short",
           s(:if,
             s(:lasgn, :x, s(:call, s(:call, nil, :obj, s(:arglist)), :x, s(:arglist))),
             s(:call, s(:lvar, :x), :do_it, s(:arglist)),
             nil))

  add_test("iteration1",
           s(:iter,
             s(:call, nil, :loop, s(:arglist)),
             nil))

  add_test("iteration2",
           s(:block,
             s(:lasgn, :array, s(:array, s(:lit, 1), s(:lit, 2), s(:lit, 3))),
             s(:iter,
               s(:call, s(:lvar, :array), :each, s(:arglist)),
               s(:lasgn, :x),
               s(:call, nil, :puts,
                 s(:arglist, s(:call, s(:lvar, :x), :to_s, s(:arglist)))))))

  add_test("iteration3",
           s(:iter,
             s(:call, s(:lit, 1), :upto, s(:arglist, s(:lit, 3))),
             s(:lasgn, :n),
             s(:call, nil, :puts,
               s(:arglist, s(:call, s(:lvar, :n), :to_s, s(:arglist))))))

  add_test("iteration4",
           s(:iter,
             s(:call, s(:lit, 3), :downto, s(:arglist, s(:lit, 1))),
             s(:lasgn, :n),
             s(:call, nil, :puts,
               s(:arglist, s(:call, s(:lvar, :n), :to_s, s(:arglist))))))

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
               s(:call, s(:lvar, :array1), :each, s(:arglist)),
               s(:lasgn, :x),
               s(:iter,
                 s(:call, s(:lvar, :array2), :each, s(:arglist)),
                 s(:lasgn, :y),
                 s(:block,
                   s(:call, nil, :puts,
                     s(:arglist, s(:call, s(:lvar, :x), :to_s, s(:arglist)))),
                   s(:call, nil, :puts,
                     s(:arglist, s(:call, s(:lvar, :y), :to_s, s(:arglist)))))))))

  add_test("iteration7",
           s(:iter,
             s(:call, nil, :a, s(:arglist)),
             s(:masgn,
               s(:array, s(:lasgn, :b), s(:lasgn, :c))),
             s(:call, nil, :p, s(:arglist, s(:lvar, :c)))))

  add_test("iteration8",
           s(:iter,
             s(:call, nil, :a, s(:arglist)),
             s(:masgn,
               s(:array, s(:lasgn, :b), s(:lasgn, :c)),
               s(:lasgn, :d)),
             s(:call, nil, :p, s(:arglist, s(:lvar, :c)))))

  add_test("iteration9",
           s(:iter,
             s(:call, nil, :a, s(:arglist)),
             s(:masgn, s(:array, s(:lasgn, :b), s(:lasgn, :c)), s(:splat)),
             s(:call, nil, :p, s(:arglist, s(:lvar, :c)))))

  add_test("iterationA", :same)

  add_test("iteration_dasgn_curr_dasgn_madness",
           s(:iter,
             s(:call, s(:call, nil, :as, s(:arglist)), :each, s(:arglist)),
             s(:lasgn, :a),
             s(:lasgn,
               :b,
               s(:call,
                 s(:lvar, :b),
                 :+,
                 s(:arglist,
                   s(:call, s(:lvar, :a), :b, s(:arglist, s(:false))))))))

  add_test("iteration_double_var",
           s(:iter,
             s(:call, nil, :a, s(:arglist)),
             s(:lasgn, :x),
             s(:iter,
               s(:call, nil, :b, s(:arglist)),
               s(:lasgn, :x),
               s(:call, nil, :puts, s(:arglist, s(:lvar, :x))))))

  add_test("iteration_masgn",
           s(:iter,
             s(:call, nil, :define_method,
               s(:arglist, s(:call, nil, :method, s(:arglist)))),
             s(:masgn, s(:lasgn, :args))))

  add_test("ivar",
           s(:defn, :reader,
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

  add_test("lit_long_negative", :same)

  add_test("lit_range2",
           s(:lit, 1..10))

  add_test("lit_range3",
           s(:lit, 1...10))

  add_test("lit_regexp",
           s(:lit, /x/))

  add_test("lit_regexp_i_wwtt",
           s(:call, s(:call, nil, :str, s(:arglist)), :split, s(:arglist, s(:lit, //i))))

  add_test("lit_regexp_n", :same)
  add_test("lit_regexp_once", :same)

  add_test("lit_sym",
           s(:lit, :x))

  add_test("lit_sym_splat", :same)

  add_test("lvar_def_boundary",
           s(:block,
             s(:lasgn, :b, s(:lit, 42)),
             s(:defn, :a,
               s(:args),
               s(:scope,
                 s(:block,
                   s(:iter,
                     s(:call, nil, :c, s(:arglist)),
                     nil, # FIX: this shouldn't be here
                     s(:begin,
                       s(:rescue,
                         s(:resbody,
                           s(:array,
                             s(:const, :RuntimeError),
                             s(:lasgn, :b, s(:gvar, :$!))),
                           s(:block,
                             s(:call, nil, :puts,
                               s(:arglist, s(:lvar, :b)))))))))))))

  add_test("masgn",
           s(:masgn,
             s(:array, s(:lasgn, :a), s(:lasgn, :b)),
             s(:array, s(:call, nil, :c, s(:arglist)), s(:call, nil, :d, s(:arglist)))))

  add_test("masgn_argscat",
           s(:masgn,
             s(:array, s(:lasgn, :a), s(:lasgn, :b)),
             s(:lasgn, :c),
             s(:argscat,
               s(:array, s(:lit, 1), s(:lit, 2)),
               s(:array, s(:lit, 3), s(:lit, 4)))))

  add_test("masgn_attrasgn",
           s(:masgn,
             s(:array,
               s(:lasgn, :a),
               s(:attrasgn, s(:call, nil, :b, s(:arglist)), :c=, s(:arglist))),
             s(:array,
               s(:call, nil, :d, s(:arglist)),
               s(:call, nil, :e, s(:arglist)))))

  add_test("masgn_iasgn",
           s(:masgn,
             s(:array, s(:lasgn, :a), s(:iasgn, :@b)),
             s(:array, s(:call, nil, :c, s(:arglist)), s(:call, nil, :d, s(:arglist)))))

  add_test("masgn_masgn", :same)

  add_test("masgn_splat",
           s(:masgn,
             s(:array, s(:lasgn, :a), s(:lasgn, :b)),
             s(:lasgn, :c),
             s(:array,
               s(:call, nil, :d, s(:arglist)), s(:call, nil, :e, s(:arglist)),
               s(:call, nil, :f, s(:arglist)), s(:call, nil, :g, s(:arglist)))))

  add_test("masgn_splat_no_name_to_ary",
           s(:masgn,
             s(:array, s(:lasgn, :a), s(:lasgn, :b)),
             s(:splat),
             s(:to_ary, s(:call, nil, :c, s(:arglist)))))

  add_test("masgn_splat_no_name_trailing",
           s(:masgn,
             s(:array, s(:lasgn, :a), s(:lasgn, :b)),
             s(:to_ary, s(:call, nil, :c, s(:arglist)))))

  add_test("masgn_splat_to_ary",
           s(:masgn,
             s(:array, s(:lasgn, :a), s(:lasgn, :b)),
             s(:lasgn, :c),
             s(:to_ary, s(:call, nil, :d, s(:arglist)))))

  add_test("masgn_splat_to_ary2",
           s(:masgn,
             s(:array, s(:lasgn, :a), s(:lasgn, :b)),
             s(:lasgn, :c),
             s(:to_ary,
               s(:call, s(:call, nil, :d, s(:arglist)), :e, s(:arglist, s(:str, 'f'))))))

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

  add_test("module_scoped", :same)
  add_test("module_scoped3", :same)

  add_test("next",
           s(:iter,
             s(:call, nil, :loop, s(:arglist)),
             nil,
             s(:if, s(:false), s(:next), nil)))

  add_test("next_arg",
           s(:iter,
             s(:call, nil, :loop, s(:arglist)),
             nil,
             s(:if, s(:false), s(:next, s(:lit, 42)), nil)))

  add_test("not",
           s(:not, s(:true)))

  add_test("nth_ref",
           s(:nth_ref, 1))

  add_test("op_asgn1",
           s(:block,
             s(:lasgn, :b, s(:zarray)),
             s(:op_asgn1, s(:lvar, :b),
               s(:array, s(:lit, 1)), "||".intern, s(:lit, 10)),
             s(:op_asgn1, s(:lvar, :b),
               s(:array, s(:lit, 2)), "&&".intern, s(:lit, 11)),
             s(:op_asgn1, s(:lvar, :b),
               s(:array, s(:lit, 3)), "+".intern, s(:lit, 12))))

  add_test("op_asgn1_ivar", :same)

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
               s(:call, s(:call, s(:lvar, :c), :d, s(:arglist)), :e, s(:arglist)),
               :f=, "||".intern, s(:lit, 42))))

  add_test("op_asgn2_self",
           s(:op_asgn2, s(:self), :"Bag=", :"||",
             s(:call, s(:const, :Bag), :new, s(:arglist))))

  add_test("op_asgn_and",
           s(:block,
             s(:lasgn, :a, s(:lit, 0)),
             s(:op_asgn_and, s(:lvar, :a), s(:lasgn, :a, s(:lit, 2)))))

  add_test("op_asgn_and_ivar2",
           s(:op_asgn_and,
             s(:ivar, :@fetcher),
             s(:iasgn,
               :@fetcher,
               s(:call,
                 nil,
                 :new,
                 s(:arglist,
                   s(:call,
                     s(:call, s(:const, :Gem), :configuration, s(:arglist)),
                     :[],
                     s(:arglist, s(:lit, :http_proxy))))))))

  add_test("op_asgn_or",
           s(:block,
             s(:lasgn, :a, s(:lit, 0)),
             s(:op_asgn_or, s(:lvar, :a), s(:lasgn, :a, s(:lit, 1)))))

  add_test("op_asgn_or_block",
           s(:op_asgn_or,
             s(:lvar, :a),
             s(:lasgn, :a,
               s(:rescue,
                 s(:call, nil, :b, s(:arglist)),
                 s(:resbody, s(:array), s(:call, nil, :c, s(:arglist)))))))

  add_test("op_asgn_or_ivar", :same)

  add_test("op_asgn_or_ivar2",
           s(:op_asgn_or,
             s(:ivar, :@fetcher),
             s(:iasgn,
               :@fetcher,
               s(:call,
                 nil,
                 :new,
                 s(:arglist,
                   s(:call,
                     s(:call, s(:const, :Gem), :configuration, s(:arglist)),
                     :[],
                     s(:arglist, s(:lit, :http_proxy))))))))

  add_test("or",
           s(:or, s(:call, nil, :a, s(:arglist)), s(:call, nil, :b, s(:arglist))))

  add_test("or_big",
           s(:or,
             s(:or,  s(:call, nil, :a, s(:arglist)), s(:call, nil, :b, s(:arglist))),
             s(:and, s(:call, nil, :c, s(:arglist)), s(:call, nil, :d, s(:arglist)))))

  add_test("or_big2",
           s(:or,
             s(:or,  s(:call, nil, :a, s(:arglist)), s(:call, nil, :b, s(:arglist))),
             s(:and, s(:call, nil, :c, s(:arglist)), s(:call, nil, :d, s(:arglist)))))

  add_test("parse_floats_as_args", :same)

  add_test("postexe", # question that variable
           s(:iter, s(:postexe), nil, s(:lit, 1)))

  add_test("proc_args_0",
           s(:iter,
             s(:call, nil, :proc, s(:arglist)),
             0,
             s(:call, s(:call, nil, :x, s(:arglist)), :+, s(:arglist, s(:lit, 1)))))

  add_test("proc_args_1",
           s(:iter,
             s(:call, nil, :proc, s(:arglist)),
             s(:lasgn, :x),
             s(:call, s(:lvar, :x), :+, s(:arglist, s(:lit, 1)))))

  add_test("proc_args_2",
           s(:iter,
             s(:call, nil, :proc, s(:arglist)),
             s(:masgn, s(:array, s(:lasgn, :x), s(:lasgn, :y))),
             s(:call, s(:lvar, :x), :+, s(:arglist, s(:lvar, :y)))))

  add_test("proc_args_no", # TODO: verify that this dasgn_curr is correct
           s(:iter,
             s(:call, nil, :proc, s(:arglist)),
             nil,
             s(:call, s(:call, nil, :x, s(:arglist)), :+, s(:arglist, s(:lit, 1)))))

  add_test("redo",
           s(:iter,
             s(:call, nil, :loop, s(:arglist)),
             nil,
             s(:if, s(:false), s(:redo), nil)))

  add_test("rescue",
           s(:rescue,
             s(:call, nil, :blah, s(:arglist)),
             s(:resbody, s(:array), s(:nil))))

  add_test("rescue_block_body",
           s(:begin,
             s(:rescue,
               s(:call, nil, :a, s(:arglist)),
               s(:resbody,
                 s(:array, s(:lasgn, :e, s(:gvar, :$!))),
                 s(:block,
                   s(:call, nil, :c, s(:arglist)),
                   s(:call, nil, :d, s(:arglist)))))))

  add_test("rescue_block_nada",
           s(:begin,
             s(:rescue,
               s(:call, nil, :blah, s(:arglist)),
               s(:resbody, s(:array), nil))))

  add_test("rescue_exceptions",
           s(:begin,
             s(:rescue,
               s(:call, nil, :blah, s(:arglist)),
               s(:resbody,
                 s(:array,
                   s(:const, :RuntimeError),
                   s(:lasgn, :r, s(:gvar, :$!))),
                 nil))))

  add_test("retry",
           s(:retry))

  add_test("return_0", :same)
  add_test("return_1", :same)
  add_test("return_n", :same)

  add_test("sclass",
           s(:sclass, s(:self), s(:scope, s(:lit, 42))))

  add_test("sclass_trailing_class",
           s(:class, :A, nil,
             s(:scope,
               s(:block,
                 s(:sclass, s(:self),
                   s(:scope, s(:call, nil, :a, s(:arglist)))),
                 s(:class, :B, nil, s(:scope))))))

  add_test("splat",
           s(:defn, :x, s(:args, :"*b"),
             s(:scope,
               s(:block,
                 s(:call, nil, :a, s(:splat, s(:lvar, :b)))))))

  add_test("str",
           s(:str, "x"))

  add_test("str_concat_newline", :same)
  add_test("str_concat_space", :same)
  add_test("str_heredoc", :same)

  add_test("str_heredoc_call",
           s(:call, s(:str, "  blah\nblah\n"), :strip, s(:arglist)))

  add_test("str_heredoc_double",
           s(:lasgn, :a,
             s(:call, s(:lvar, :a), :+,
               s(:arglist,
                 s(:call,
                   s(:call, s(:str, "  first\n"), :+,
                     s(:arglist, s(:call, nil, :b, s(:arglist)))),
                   :+,
                   s(:arglist, s(:str, "  second\n")))))))

  add_test("str_heredoc_indent", :same)
  add_test("str_interp_file", :same)

  add_test("structure_extra_block_for_dvar_scoping",
           s(:iter,
            s(:call, s(:call, nil, :a, s(:arglist)), :b, s(:arglist)),
            s(:masgn, s(:array, s(:lasgn, :c), s(:lasgn, :d))),
             s(:if,
               s(:call, s(:call, nil, :e, s(:arglist)), :f, s(:arglist, s(:lvar, :c))),
               nil,
               s(:block,
                 s(:lasgn, :g, s(:false)),
                 s(:iter,
                   s(:call, s(:lvar, :d), :h, s(:arglist)),
                   s(:masgn, s(:array, s(:lasgn, :x), s(:lasgn, :i))),
                   s(:lasgn, :g, s(:true)))))))

  add_test("structure_remove_begin_1",
           s(:call, s(:call, nil, :a, s(:arglist)), :<<,
             s(:arglist, s(:rescue, s(:call, nil, :b, s(:arglist)),
                           s(:resbody, s(:array), s(:call, nil, :c, s(:arglist)))))))

  add_test("structure_remove_begin_2",
           s(:block,
            s(:lasgn,
             :a,
             s(:if, s(:call, nil, :c, s(:arglist)),
              s(:rescue, s(:call, nil, :b, s(:arglist)), s(:resbody, s(:array), s(:nil))),
              nil)),
            s(:lvar, :a)))

  add_test("structure_unused_literal_wwtt", :same)

  add_test("super",
           s(:defn, :x,
             s(:args), s(:scope, s(:block, s(:super, s(:array, s(:lit, 4)))))))

  add_test("super_block_pass",
           s(:block_pass,
             s(:call, nil, :b, s(:arglist)),
             s(:super, s(:array, s(:call, nil, :a, s(:arglist))))))

  add_test("super_block_splat",
           s(:super,
             s(:argscat,
               s(:array, s(:call, nil, :a, s(:arglist))), s(:call, nil, :b, s(:arglist)))))

  add_test("super_multi",
           s(:defn, :x,
             s(:args),
             s(:scope,
               s(:block,
                 s(:super, s(:array, s(:lit, 4), s(:lit, 2), s(:lit, 1)))))))

  add_test("svalue",
           s(:lasgn, :a, s(:svalue, s(:splat, s(:call, nil, :b, s(:arglist))))))

  add_test("to_ary",
           s(:masgn,
             s(:array, s(:lasgn, :a), s(:lasgn, :b)),
             s(:to_ary, s(:call, nil, :c, s(:arglist)))))

  add_test("true",
           s(:true))

  add_test("undef", :same)
  add_test("undef_2", :same)
  add_test("undef_3", :same)

  add_test("undef_block_1",
           s(:block,
             s(:call, nil, :f1, s(:arglist)),
             s(:undef, s(:lit, :x))))

  add_test("undef_block_2",
           s(:block,
             s(:call, nil, :f1, s(:arglist)),
             s(:block,
               s(:undef, s(:lit, :x)),
               s(:undef, s(:lit, :y)))))

  add_test("undef_block_3",
           s(:block,
             s(:call, nil, :f1, s(:arglist)),
             s(:block,
               s(:undef, s(:lit, :x)),
               s(:undef, s(:lit, :y)),
               s(:undef, s(:lit, :z)))))

  add_test("undef_block_3_post",
           s(:block,
             s(:undef, s(:lit, :x)),
             s(:undef, s(:lit, :y)),
             s(:undef, s(:lit, :z)),
             s(:call, nil, :f2, s(:arglist))))

  add_test("undef_block_wtf",
           s(:block,
             s(:call, nil, :f1, s(:arglist)),
             s(:block,
               s(:undef, s(:lit, :x)),
               s(:undef, s(:lit, :y)),
               s(:undef, s(:lit, :z))),
             s(:call, nil, :f2, s(:arglist))))

  add_test("until_post",
           s(:until, s(:false),
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))),
             false))

  add_test("until_post_not",
           s(:while, s(:true),
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))), false))

  add_test("until_pre",
           s(:until, s(:false),
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))),
             true))

  add_test("until_pre_mod",
           s(:until, s(:false),
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))), true))

  add_test("until_pre_not",
           s(:while, s(:true),
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))), true))

  add_test("until_pre_not_mod",
           s(:while, s(:true),
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))), true))

  add_test("valias",
           s(:valias, :$y, :$x))

  add_test("vcall",
           s(:call, nil, :method, s(:arglist)))

  add_test("while_post",
           s(:while, s(:false),
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))), false))

  add_test("while_post_not",
           s(:until, s(:true),
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))), false))

  add_test("while_pre",
           s(:while, s(:false),
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))), true))

  add_test("while_pre_mod",
           s(:while, s(:false),
            s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))), true))

  add_test("while_pre_nil",
           s(:while, s(:false), nil, true))

  add_test("while_pre_not",
           s(:until, s(:true),
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))), true))

  add_test("while_pre_not_mod",
           s(:until, s(:true),
             s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))),
             true))

  add_test("xstr",
           s(:xstr, "touch 5"))

  add_test("yield",
           s(:yield))

  add_test("yield_arg",
           s(:yield, s(:lit, 42)))

  add_test("yield_args",
           s(:yield, s(:array, s(:lit, 42), s(:lit, 24))))

  add_test("zarray",
           s(:lasgn, :a, s(:zarray)))

  add_test("zsuper",
           s(:defn, :x, s(:args), s(:scope, s(:block, s(:zsuper)))))
end
