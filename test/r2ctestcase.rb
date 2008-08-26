require 'test/unit/testcase'
require 'sexp_processor' # for deep_clone FIX
require 'typed_sexp'
require 'pt_testcase'
require 'unique'

# TODO: str -> char * in ansi c
# TODO: add tests that mix types up to fuck up RubyC type checker

class R2CTestCase < ParseTreeTestCase

  testcase_order.push(*%w(Ruby ParseTree Rewriter TypeChecker
                          CRewriter RubyToAnsiC RubyToRubyC))

  add_tests("alias",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("alias_ugh",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("and",
            "Rewriter"    => :same,
            "TypeChecker" => t(:and,
                               t(:call, nil, :a, t(:arglist), Type.bool),
                               t(:call, nil, :b, t(:arglist), Type.bool),
                               Type.bool),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "a() && b()",
            "RubyToRubyC" => 'rb_funcall(self, rb_intern("a"), 0) && rb_funcall(self, rb_intern("b"), 0)')

  add_tests("argscat_inside",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("argscat_svalue",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("argspush",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("array",
            "Rewriter"    => :same,
            "TypeChecker" => t(:array,
                               t(:lit, 1, Type.long),
                               t(:lit, :b, Type.symbol),
                               t(:str, "c", Type.str),
                               Type.hetero),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "1, \"b\", \"c\"",
            "RubyToRubyC" => "LONG2NUM(1), ID2SYM(rb_intern(\"b\")), rb_str_new2(\"c\")")

  add_tests("array_pct_W",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("attrasgn",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("attrasgn_index_equals",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("attrasgn_index_equals_space",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("attrset",
            "Rewriter"    => s(:defn, :writer=,
                               s(:args, :arg),
                               s(:scope,
                                 s(:block,
                                   s(:return,
                                     s(:iasgn, :@writer, s(:lvar, :arg)))))),
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("back_ref",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("begin",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("begin_def",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("begin_rescue_ensure",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("begin_rescue_twice",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("begin_rescue_twice_mri_verbose_flag",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_attrasgn",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_lasgn",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_mystery_block",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_pass_args_and_splat",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_pass_call_0",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_pass_call_1",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_pass_call_n",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_pass_fcall_0",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_pass_fcall_1",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_pass_fcall_n",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_pass_omgwtf",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_pass_splat",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_pass_super",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_pass_thingy",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_stmt_after",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_stmt_after_mri_verbose_flag",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_stmt_before",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_stmt_before_mri_verbose_flag",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_stmt_both",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("block_stmt_both_mri_verbose_flag",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("bmethod",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("bmethod_noargs",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("bmethod_splat",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("bools", # TODO: not in pttc
            "Rewriter"    => :skip,
            # TODO: why does return false have type void?
            "TypeChecker" => t(:defn, :bools,
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
                               Type.function(Type.unknown,
                                             [Type.value], Type.bool)),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "bool\nbools(void * arg1) {\nif (arg1) {\nreturn 0;\n} else {\nreturn 1;\n}\n}",
            "RubyToRubyC" => "static VALUE\nrrc_c_bools(VALUE self, VALUE arg1) {\nif (NIL_P(arg1)) {\nreturn Qfalse;\n} else {\nreturn Qtrue;\n}\n}")

  add_tests("break",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("break_arg",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("call",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("call_arglist",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("call_arglist_hash",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("call_arglist_norm_hash",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("call_arglist_norm_hash_splat",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("call_attrasgn", # TODO: not in pttc
            "Rewriter"    => :skip,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("call_command",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("call_expr",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("call_index",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("call_index_no_args",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("call_index_space",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("call_self", # TODO: not in pttc
            "Rewriter"    => :skip,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("call_unary_neg",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("case",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("case_nested",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("case_nested_inner_no_expr",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("case_no_expr",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("case_splat",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("case_stmt", # TODO: not in pttc
            "Rewriter"    => :skip,
            "TypeChecker" => t(:defn, :case_stmt,
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
                                       t(:arglist, t(:lit, 1, Type.long)),
                                       Type.bool),
                                     t(:block,
                                       t(:call,
                                         nil,
                                         :puts,
                                         t(:arglist,
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
                                           t(:arglist, t(:lit, 2, Type.long)),
                                           Type.bool),
                                         t(:call,
                                           t(:lvar, :var, Type.long),
                                           :case_equal_long,
                                           t(:arglist, t(:lit, 3, Type.long)),
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
                                           t(:arglist, t(:lit, 4, Type.long)),
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
                                       t(:arglist, t(:str, "red", Type.str)),
                                       Type.bool),
                                     t(:lasgn, :var, t(:lit, 1, Type.long), Type.long),
                                     t(:if,
                                       t(:call,
                                         t(:lvar, :result, Type.str),
                                         :case_equal_str,
                                         t(:arglist, t(:str, "yellow", Type.str)),
                                         Type.bool),
                                       t(:lasgn, :var, t(:lit, 2, Type.long), Type.long),
                                       t(:if,
                                         t(:call,
                                           t(:lvar, :result, Type.str),
                                           :case_equal_str,
                                           t(:arglist,
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
                               Type.function(Type.unknown, [], Type.str)),
            "CRewriter"   => :same,
            # HACK: I don't like the semis after the if blocks, but it is a compromise right now
            "RubyToAnsiC" => "str\ncase_stmt() {\nstr result;\nlong var;\nvar = 2;\nresult = \"\";\nif (case_equal_long(var, 1)) {\nputs(\"something\");\nresult = \"red\";\n} else {\nif (case_equal_long(var, 2) || case_equal_long(var, 3)) {\nresult = \"yellow\";\n} else {\nif (case_equal_long(var, 4)) {\n;\n} else {\nresult = \"green\";\n}\n}\n};\nif (case_equal_str(result, \"red\")) {\nvar = 1;\n} else {\nif (case_equal_str(result, \"yellow\")) {\nvar = 2;\n} else {\nif (case_equal_str(result, \"green\")) {\nvar = 3;\n}\n}\n};\nreturn result;\n}",
            "RubyToRubyC" => "static VALUE\nrrc_c_case_stmt(VALUE self) {\nVALUE result;\nVALUE var;\nvar = LONG2NUM(2);\nresult = rb_str_new2(\"\");\nif (rb_funcall(var, rb_intern(\"===\"), 1, LONG2NUM(1))) {\nrb_funcall(self, rb_intern(\"puts\"), 1, rb_str_new2(\"something\"));\nresult = rb_str_new2(\"red\");\n} else {\nif (rb_funcall(var, rb_intern(\"===\"), 1, LONG2NUM(2)) || rb_funcall(var, rb_intern(\"===\"), 1, LONG2NUM(3))) {\nresult = rb_str_new2(\"yellow\");\n} else {\nif (rb_funcall(var, rb_intern(\"===\"), 1, LONG2NUM(4))) {\n;\n} else {\nresult = rb_str_new2(\"green\");\n}\n}\n};\nif (rb_funcall(result, rb_intern(\"===\"), 1, rb_str_new2(\"red\"))) {\nvar = LONG2NUM(1);\n} else {\nif (rb_funcall(result, rb_intern(\"===\"), 1, rb_str_new2(\"yellow\"))) {\nvar = LONG2NUM(2);\n} else {\nif (rb_funcall(result, rb_intern(\"===\"), 1, rb_str_new2(\"green\"))) {\nvar = LONG2NUM(3);\n}\n}\n};\nreturn result;\n}")

  add_tests("cdecl",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("class_plain",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("class_scoped",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("class_scoped3",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("class_super_array",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("class_super_expr",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("class_super_object",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("colon2",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("colon3",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("conditional1",
            "Rewriter"    => :same,
            "TypeChecker" => t(:if,
                               t(:call, t(:lit, 42, Type.long), :==,
                                 t(:arglist, t(:lit, 0, Type.long)),
                                 Type.bool),
                               t(:return, t(:lit, 1, Type.long), Type.void),
                               nil,
                               Type.void),
            "CRewriter"   => t(:if,
                               t(:call, t(:lit, 42, Type.long), :==,
                                 t(:arglist, t(:lit, 0, Type.long)),
                                 Type.bool),
                               t(:return, t(:lit, 1, Type.long), Type.void),
                               nil,
                               Type.void),
            "RubyToAnsiC" => "if (42 == 0) {\nreturn 1;\n}",
            "RubyToRubyC" => "if (rb_funcall(LONG2NUM(42), rb_intern(\"==\"), 1, LONG2NUM(0))) {\nreturn LONG2NUM(1);\n}")

  add_tests("conditional2",
            "Rewriter"    => :same,
            "TypeChecker" => t(:if,
                               t(:call,
                                 t(:lit, 42, Type.long),
                                 :==,
                                 t(:arglist,
                                   t(:lit, 0, Type.long)),
                                 Type.bool),
                               nil,
                               t(:return, t(:lit, 2, Type.long), Type.void),
                               Type.void),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "if (42 == 0) {\n;\n} else {\nreturn 2;\n}",
            "RubyToRubyC" => "if (rb_funcall(LONG2NUM(42), rb_intern(\"==\"), 1, LONG2NUM(0))) {\n;\n} else {\nreturn LONG2NUM(2);\n}")

  add_tests("conditional3",
            "Rewriter"    => :same,
            "TypeChecker" => t(:if,
                               t(:call,
                                 t(:lit, 42, Type.long),
                                 :==,
                                 t(:arglist,
                                   t(:lit, 0, Type.long)),
                                 Type.bool),
                               t(:return,
                                 t(:lit, 3, Type.long),

                                 Type.void),
                               t(:return,
                                 t(:lit, 4, Type.long),
                                 Type.void),
                               Type.void),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "if (42 == 0) {\nreturn 3;\n} else {\nreturn 4;\n}",
            "RubyToRubyC" => "if (rb_funcall(LONG2NUM(42), rb_intern(\"==\"), 1, LONG2NUM(0))) {\nreturn LONG2NUM(3);\n} else {\nreturn LONG2NUM(4);\n}")

  add_tests("conditional4",
            "Rewriter"    => :same,
            "TypeChecker" => t(:if,
                               t(:call,
                                 t(:lit, 42, Type.long),
                                 :==,
                                 t(:arglist,
                                   t(:lit, 0, Type.long)),
                                 Type.bool),
                               t(:return,
                                 t(:lit, 2, Type.long),
                                 Type.void),
                               t(:if,
                                 t(:call,
                                   t(:lit, 42, Type.long),
                                   :<,
                                   t(:arglist,
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
            "CRewriter"   => :same,
            "RubyToAnsiC" => "if (42 == 0) {\nreturn 2;\n} else {\nif (42 < 0) {\nreturn 3;\n} else {\nreturn 4;\n}\n}",
            "RubyToRubyC" => "if (rb_funcall(LONG2NUM(42), rb_intern(\"==\"), 1, LONG2NUM(0))) {\nreturn LONG2NUM(2);\n} else {\nif (rb_funcall(LONG2NUM(42), rb_intern(\"<\"), 1, LONG2NUM(0))) {\nreturn LONG2NUM(3);\n} else {\nreturn LONG2NUM(4);\n}\n}")

  add_tests("conditional5",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("conditional_post_if",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("conditional_post_if_not",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("conditional_post_unless",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("conditional_post_unless_not",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("conditional_pre_if",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("conditional_pre_if_not",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("conditional_pre_unless",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("conditional_pre_unless_not",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("const",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("constX",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("constY",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("constZ",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("cvar",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("cvasgn",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("cvasgn_cls_method",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("cvdecl",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dasgn_0",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dasgn_1",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dasgn_2",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dasgn_curr",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dasgn_icky",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dasgn_mixed",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defined",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defn_args_mand_opt_block",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defn_args_mand_opt_splat",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defn_args_mand_opt_splat_block",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defn_args_mand_opt_splat_no_name",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defn_args_opt_block",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defn_args_opt_splat_no_name",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defn_bbegin", # TODO: not in pttc
            "Rewriter"    => :skip,
            "TypeChecker" => t(:defn, :bbegin,
                               t(:args),
                               t(:scope,
                                 t(:block,
                                   t(:begin,
                                     t(:ensure,
                                       t(:rescue,
                                         t(:call,
                                           t(:lit, 1, Type.long),
                                           :+,
                                           t(:arglist, t(:lit, 1, Type.long)), Type.long),
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
                               Type.function(Type.unknown, [], Type.void)),
            "CRewriter"   => :same,
            "RubyToAnsiC" => :unsupported,
            "RubyToRubyC" => :unsupported)

  add_tests("defn_bmethod_added", # TODO: not in pttc
            "Rewriter"    => :skip,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defn_empty",
            "Rewriter"    => :same,
            "TypeChecker" => t(:defn, :empty,
                               t(:args),
                               t(:scope,
                                 t(:block,
                                   t(:nil, Type.value),
                                   Type.unknown),
                                 Type.void),
                               Type.function(Type.unknown, [], Type.void)),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "void\nempty() {\nNULL;\n}",
            "RubyToRubyC" => "static VALUE\nrrc_c_empty(VALUE self) {\nQnil;\n}")

  add_tests("defn_empty_args",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defn_fbody", # TODO: not in pttc
            "Rewriter"    => :skip,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defn_is_something", # TODO: not in pttc
            "Rewriter"    => :skip,
            "TypeChecker" => t(:defn, :something?,
                               t(:args),
                               t(:scope,
                                 t(:block,
                                   t(:nil, Type.value),
                                   Type.unknown),
                                 Type.void),
                               Type.function(Type.unknown, [], Type.void)),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "void\nis_something() {\nNULL;\n}",
            "RubyToRubyC" => "static VALUE\nrrc_c_is_something(VALUE self) {\nQnil;\n}")

  add_tests("defn_lvar_boundary",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defn_optargs",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defn_or",
            "Rewriter"    => :same,
            "TypeChecker" => t(:defn, :|,
                               t(:args, t(:o, Type.unknown)),
                               t(:scope,
                                 t(:block,
                                   t(:nil, Type.value),
                                   Type.unknown),
                                 Type.void),
                               Type.function(Type.unknown, [Type.unknown],
                                             Type.void)),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "void\nor(void * o) {\nNULL;\n}",
            "RubyToRubyC" => "static VALUE\nrrc_c_or(VALUE self, VALUE o) {\nQnil;\n}")

  add_tests("defn_rescue",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defn_rescue_mri_verbose_flag",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defn_something_eh",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defn_splat_no_name",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defn_zarray",
            "Rewriter"    => :same,
            "TypeChecker" => t(:defn,
                               :zarray,
                               t(:args),
                               t(:scope,
                                 t(:block,
                                   t(:lasgn, :a, t(:array), Type.unknown_list),
                                   t(:return,
                                     t(:lvar,
                                       :a, Type.unknown_list), Type.void),
                                   Type.unknown), Type.void),
                               Type.function(Type.unknown, [], Type.unknown_list)),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "void *\nzarray() {\nvoid * a;\na = (void *) malloc(sizeof(void *) * 0);\nreturn a;\n}",
            "RubyToRubyC" => "static VALUE\nrrc_c_zarray(VALUE self) {\nVALUE a;\na = rb_ary_new2(0);\nreturn a;\n}")

  add_tests("defs",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defs_args_mand_opt_splat_block",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defs_empty",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("defs_empty_args",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dmethod",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dmethod_added", # TODO: not in pttc
            "Rewriter"    => :skip,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dot2",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dot3",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dregx",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dregx_interp",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dregx_n",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dregx_once",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dregx_once_n_interp",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dstr",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dstr_2",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dstr_3",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dstr_concat",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dstr_gross",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dstr_heredoc_expand",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dstr_heredoc_windoze_sucks",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dstr_heredoc_yet_again",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dstr_nest",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dstr_str_lit_start",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dstr_the_revenge",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dsym",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("dxstr",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("ensure",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("false",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("fbody",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("fcall_arglist",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("fcall_arglist_hash",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("fcall_arglist_norm_hash",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("fcall_arglist_norm_hash_splat",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("fcall_block",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("fcall_index_space",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("fcall_keyword",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("flip2",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("flip2_method",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("flip3",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("for",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("for_no_body",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("gasgn",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("global",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            # TODO: test s(:gvar, :$stderr) != t(:gvar, $stderr, Type.file)
            "TypeChecker" => t(:gvar, :$stderr, Type.file),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "stderr",
            "RubyToRubyC" => "rb_gv_get(\"$stderr\")")

  add_tests("gvar",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("gvar_underscore",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("gvar_underscore_blah",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("hash",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("hash_rescue",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("iasgn",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("if_block_condition",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("if_lasgn_short",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("interpolated", # TODO: not in pttc
            "Rewriter"    => :skip,
            "TypeChecker" => t(:dstr,
                               "var is ",
                               t(:lvar, :argl, Type.long),
                               t(:str, ". So there.", Type.str),
                               Type.str),
            "CRewriter"   => :same,
            "RubyToAnsiC" => :unsupported,
            "RubyToRubyC" => "rb_funcall(rb_mKernel, rb_intern(\"sprintf\"), 4, rb_str_new2(\"%s%s%s\"), rb_str_new2(\"var is \"), argl, rb_str_new2(\". So there.\"))")

  add_tests("iter", # TODO: not in pttc
            "Rewriter"    => :skip,
            "TypeChecker" => t(:iter,
                               t(:call, nil, :loop, nil, Type.unknown),
                               t(:dasgn_curr, :temp_1, Type.unknown),
                               nil,
                               Type.unknown),
            "CRewriter"   => :skip, # HACK don't do rb_iterate stuff for loop
            # "CRewriter"   => [:defx,
            #                   t(:iter,
            #                     t(:call, nil, :loop, nil, Type.unknown),
            #                     t(:args,
            #                       t(:array, t(:dasgn_curr, :temp_1, Type.unknown), Type.void),
            #                       t(:array, Type.void), Type.void),
            #                     t(:call, nil, :temp_1, nil)),
            #                   [t(:defx,
            #                      :temp_2,
            #                      t(:args, :temp_2, :temp_3),
            #                      t(:scope, t(:block, nil)), Type.void)]],
            "RubyToAnsiC" => "",
            "RubyToRubyC" => "")

  add_tests("iteration1",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("iteration2",
            "Rewriter"    => :same,
            "TypeChecker" => t(:block,
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
                                   t(:arglist), Type.unknown),
                                 t(:lasgn, :x, nil, Type.long),
                                 t(:call, nil, :puts,
                                   t(:arglist,
                                     t(:call,
                                       t(:lvar, :x, Type.long),
                                       :to_s,
                                       t(:arglist),
                                       Type.str)),
                                   Type.void),
                                 Type.void),
                               Type.unknown),
            "CRewriter"   => [:defx,
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
                                   t(:arglist), Type.unknown),
                                 t(:args,
                                   t(:array, t(:lvar, :x, Type.value), Type.void),
                                   t(:array, t(:lvar, :static_temp_4, Type.value), Type.void),
                                   Type.void),
                                 :temp_1),
                               Type.unknown),
                            [t(:static, "static VALUE static_temp_4;", Type.fucked),
                             t(:defx,
                               :temp_1,
                               t(:args,
                                 t(:temp_2, Type.value),
                                 t(:temp_3, Type.value)),
                               t(:scope,
                                 t(:block,
                                   t(:lasgn, :x,
                                     t(:lvar, :static_temp_4, Type.value),
                                     Type.value),
                                    t(:masgn,
                                      t(:array),
                                      t(:to_ary,
                                        t(:lvar, :temp_2, Type.value))),
                                   t(:call,
                                     nil,
                                     :puts,
                                     t(:arglist,
                                       t(:call,
                                         t(:lvar, :x, Type.long),
                                         :to_s,
                                         t(:arglist),
                                         Type.str)),
                                     Type.void),
                                   t(:lasgn,
                                     :static_temp_4,
                                     t(:lvar, :x, Type.value),
                                     Type.value),
                                   t(:return, t(:nil, Type.value)))),
                              Type.void)]],
            "RubyToAnsiC" => :skip, # because eric sucks soooo much
            # 'unsigned long index_x;
            # for (index_x = 0; arrays[index_x] != NULL; ++index_x) {
            # str x = arrays[index_x];
            # puts(x);
            # }',
            "RubyToRubyC" => :skip # indeed, there is an masgn when defx created
            # [:defx,
            #  "array = rb_ary_new2(3);
            #   rb_ary_store(array, 0, LONG2NUM(1));
            #   rb_ary_store(array, 1, LONG2NUM(2));
            #   rb_ary_store(array, 2, LONG2NUM(3));
            #   static_temp_4 = x;
            #   rb_iterate(rb_each, array, temp_1, Qnil);
            #   x = static_temp_4;
            #  ",
            # ["static VALUE static_temp_4;",
            #  "static VALUE
            #   rrc_c_temp_1(VALUE temp_2, VALUE temp_3) {
            #   VALUE arrays;
            #   VALUE x;
            #   arrays = static_temp_4;
            #   x = temp_2;
            #   rb_funcall(self, rb_intern(\"puts\"), 1, x);
            #   static_temp_4 = arrays;
            #   return Qnil;
            #   }"]]
            )

  add_tests("iteration3",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("iteration4",
            "Rewriter"    => :same,
            "TypeChecker" => t(:iter,
                               t(:call,
                                 t(:lit, 3, Type.long),
                                 :downto,
                                 t(:arglist, t(:lit, 1, Type.long)),
                                 Type.unknown),
                               t(:lasgn, :n, nil, Type.long),
                               t(:call, nil, :puts,
                                 t(:arglist,
                                   t(:call,
                                     t(:lvar, :n, Type.long),
                                     :to_s,
                                     t(:arglist),
                                     Type.str)),
                                 Type.void),
                               Type.void),
            "CRewriter"   => :skip,
            "RubyToAnsiC" => "n = 1;\nwhile (n <= 3) {\nputs(to_s(n));\nn = n + 1;\n}",
            "RubyToRubyC" => "n = LONG2NUM(1);\nwhile (rb_funcall(n, rb_intern(\"<=\"), 1, LONG2NUM(3))) {\nrb_funcall(self, rb_intern(\"puts\"), 1, rb_funcall(n, rb_intern(\"to_s\"), 0));\nn = rb_funcall(n, rb_intern(\"+\"), 1, LONG2NUM(1));\n}")

  add_tests("iteration5",
            "Rewriter"    => :same,
            "TypeChecker" => t(:block,
                               t(:lasgn, :argl,
                                 t(:lit, 10, Type.long), Type.long),
                               t(:while,
                                 t(:call,
                                   t(:lvar, :argl, Type.long),
                                   :>=,
                                   t(:arglist, t(:lit, 1, Type.long)), Type.bool),
                                 t(:block,
                                   t(:call, nil, :puts,
                                     t(:arglist,
                                       t(:str, 'hello', Type.str)),
                                     Type.void),
                                   t(:lasgn, :argl,
                                     t(:call,
                                       t(:lvar, :argl, Type.long),
                                       :-,
                                       t(:arglist, t(:lit, 1, Type.long)),
                                       Type.long),
                                     Type.long),
                                   Type.unknown), true),
                               Type.unknown),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "argl = 10;\nwhile (argl >= 1) {\nputs(\"hello\");\nargl = argl - 1;\n}\n",
            "RubyToRubyC" => "argl = LONG2NUM(10);\nwhile (rb_funcall(argl, rb_intern(\">=\"), 1, LONG2NUM(1))) {\nrb_funcall(self, rb_intern(\"puts\"), 1, rb_str_new2(\"hello\"));\nargl = rb_funcall(argl, rb_intern(\"-\"), 1, LONG2NUM(1));\n}\n")

  add_tests("iteration6",
            "Rewriter"    => :same,
            "TypeChecker" => t(:block,
                               t(:lasgn, :array1,
                                 t(:array,
                                   t(:lit, 1, Type.long),
                                   t(:lit, 2, Type.long),
                                   t(:lit, 3, Type.long)), Type.long_list),
                                t(:lasgn, :array2,
                                  t(:array,
                                    t(:lit, 4, Type.long),
                                    t(:lit, 5, Type.long),
                                    t(:lit, 6, Type.long),
                                    t(:lit, 7, Type.long)), Type.long_list),
                                t(:iter,
                                  t(:call,
                                    t(:lvar, :array1, Type.long_list),
                                    :each,
                                    t(:arglist), Type.unknown),
                                  t(:lasgn, :x, nil, Type.long),
                                  t(:iter,
                                    t(:call,
                                      t(:lvar, :array2, Type.long_list),
                                      :each,
                                      t(:arglist), Type.unknown),
                                    t(:lasgn, :y, nil, Type.long),
                                    t(:block,
                                      t(:call, nil, :puts,
                                        t(:arglist,
                                          t(:call,
                                            t(:lvar, :x, Type.long),
                                            :to_s,
                                            t(:arglist), Type.str)),
                                        Type.void),
                                      t(:call, nil, :puts,
                                        t(:arglist,
                                          t(:call,
                                            t(:lvar, :y, Type.long),
                                            :to_s,
                                            t(:arglist), Type.str)),
                                        Type.void),
                                      Type.unknown),
                                    Type.void),
                                  Type.void),
                                Type.unknown),
            "CRewriter"   => :skip,
            "RubyToAnsiC" => 'while (argl >= 1) {
puts("hello");
argl = argl - 1;
}',
            "RubyToRubyC" => 'while (rb_funcall(argl, rb_intern(">="), 1, LONG2NUM(1))) {
rb_funcall(self, rb_intern("puts"), 1, rb_str_new2("hello"));
argl = rb_funcall(argl, rb_intern("-"), 1, LONG2NUM(1));
}')

  add_tests("iteration7",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("iteration8",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("iteration9",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("iterationA",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("iteration_dasgn_curr_dasgn_madness",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("iteration_double_var",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("iteration_masgn",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("ivar",
            "Rewriter"    => s(:defn, :reader,
                               s(:args),
                               s(:scope, s(:block,
                                           s(:return, s(:ivar, :@reader))))),
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  # TODO: this might still be too much
  add_tests("lasgn_array",
            "Rewriter"    => :same,
            "TypeChecker" => t(:lasgn,
                               :var,
                               t(:array,
                                 t(:str, "foo", Type.str),
                                 t(:str, "bar", Type.str)),
                               Type.str_list),
            "CRewriter"   => :same,
            "RubyToRubyC" => 'var = rb_ary_new2(2);
rb_ary_store(var, 0, rb_str_new2("foo"));
rb_ary_store(var, 1, rb_str_new2("bar"))',
            "RubyToAnsiC" => 'var = (str) malloc(sizeof(str) * 2);
var[0] = "foo";
var[1] = "bar"')

  add_tests("lasgn_call",
            "Rewriter"    => :same,
            "TypeChecker" => t(:lasgn, :c,
                               t(:call,
                                 t(:lit, 2, Type.long),
                                 :+,
                                 t(:arglist,
                                   t(:lit, 3, Type.long)),
                                 Type.long),
                               Type.long),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "c = 2 + 3", # FIX: probably not "c =
            "RubyToRubyC" => 'c = rb_funcall(LONG2NUM(2), rb_intern("+"), 1, LONG2NUM(3))')

  add_tests("lit_bool_false",
            "Rewriter"    => :same,
            "TypeChecker" => t(:false, Type.bool),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "0",
            "RubyToRubyC" => "Qfalse")

  add_tests("lit_bool_true",
            "Rewriter"    => :same,
            "TypeChecker" => t(:true, Type.bool),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "1",
            "RubyToRubyC" => "Qtrue")

  add_tests("lit_float",
            "Rewriter"    => :same,
            "TypeChecker" => t(:lit, 1.1, Type.float),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "1.1",
            "RubyToRubyC" => "rb_float_new(1.1)")

  add_tests("lit_long",
            "Rewriter"    => :same,
            "TypeChecker" => t(:lit, 1, Type.long),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "1",
            "RubyToRubyC" => "LONG2NUM(1)")

  add_tests("lit_long_negative",
            "Rewriter"    => :same,
            "TypeChecker" => t(:lit, -1, Type.long),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "-1",
            "RubyToRubyC" => "LONG2NUM(-1)")

  add_tests("lit_range2",
            "Rewriter"    => :same,
            "TypeChecker" => t(:lit, 1..10, Type.range),
            "CRewriter"   => :same,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("lit_range3",
            "Rewriter"    => :same,
            "TypeChecker" => t(:lit, 1...10, Type.range),
            "CRewriter"   => :same,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("lit_regexp",
            "Rewriter"    => :same,
            "TypeChecker" => t(:lit, /x/, Type.regexp),
            "CRewriter"   => :same,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("lit_regexp_i_wwtt",
            "Rewriter"    => :same,
            "TypeChecker" => t(:call,
                               t(:call, nil, :str, t(:arglist), Type.unknown),
                               :split,
                               t(:arglist, t(:lit, //i, Type.regexp)),
                               Type.unknown),
            "CRewriter"   => :same,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("lit_regexp_n",
            "Rewriter"    => :same,
            "TypeChecker" => t(:lit, /x/n, Type.regexp),
            "CRewriter"   => :same,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("lit_regexp_once",
            "Rewriter"    => :same,
            "TypeChecker" => t(:lit, /x/, Type.regexp), # HACK - once?
            "CRewriter"   => :same,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("lit_str", # TODO: not in pttc
            "ParseTree"   => s(:str, "x"),
            "Rewriter"    => :same,
            "TypeChecker" => t(:str, "x", Type.str),
            "CRewriter"   => :same,
            "RubyToAnsiC" => '"x"',
            "RubyToRubyC" => 'rb_str_new2("x")')

  add_tests("lit_sym",
            "Rewriter"    => :same,
            "TypeChecker" => t(:lit, :x, Type.symbol),
            "CRewriter"   => :same,
            "RubyToAnsiC" => '"x"', # HACK WRONG! (or... is it?
            "RubyToRubyC" => 'ID2SYM(rb_intern("x"))')

  add_tests("lit_sym_splat",
            "Rewriter"    => :same,
            "TypeChecker" => t(:lit, :"*args", Type.symbol),
            "CRewriter"   => :same,
            "RubyToAnsiC" => '"*args"',
            "RubyToRubyC" => 'ID2SYM(rb_intern("*args"))')

  add_tests("lvar_def_boundary",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("masgn",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("masgn_argscat",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("masgn_attrasgn",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("masgn_attrasgn_idx",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("masgn_iasgn",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("masgn_masgn",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("masgn_splat",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("masgn_splat_no_name_to_ary",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("masgn_splat_no_name_trailing",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("masgn_splat_to_ary",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("masgn_splat_to_ary2",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("match",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("match2",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("match3",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("module",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("module_scoped",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("module_scoped3",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("multi_args", # TODO: not in pttc
            "Ruby"        => "def multi_args(arg1, arg2)
                                arg3 = arg1 * arg2 * 7
                                puts arg3.to_s
                                return \"foo\"
                              end",
            "ParseTree"   => s(:defn, :multi_args,
                               s(:args, :arg1, :arg2),
                               s(:scope,
                                 s(:block,
                                   s(:lasgn,
                                     :arg3,
                                     s(:call,
                                       s(:call,
                                         s(:lvar, :arg1),
                                         :*,
                                         s(:arglist, s(:lvar, :arg2))),
                                       :*,
                                       s(:arglist, s(:lit, 7)))),
                                   s(:call,
                                     nil,
                                     :puts,
                                     s(:arglist, s(:call, s(:lvar, :arg3),
                                                   :to_s, s(:arglist)))),
                                   s(:return, s(:str, "foo"))))),
            "Rewriter"    => :same,
            "TypeChecker" => t(:defn, :multi_args,
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
                                         t(:arglist, t(:lvar, :arg2, Type.long)),
                                         Type.long),
                                       :*,
                                       t(:arglist, t(:lit, 7, Type.long)),
                                       Type.long),
                                     Type.long),
                                   t(:call,
                                     nil,
                                     :puts,
                                     t(:arglist,
                                       t(:call,
                                         t(:lvar, :arg3, Type.long),
                                         :to_s,
                                         t(:arglist),
                                         Type.str)),
                                     Type.void),
                                   t(:return, t(:str, "foo", Type.str),
                                     Type.void),
                                   Type.unknown),
                                 Type.void),
                               Type.function(Type.unknown,
                                             [Type.long, Type.long], Type.str)),
            "CRewriter"   => :same,
            "RubyToRubyC" => "static VALUE
rrc_c_multi_args(VALUE self, VALUE arg1, VALUE arg2) {
VALUE arg3;
arg3 = rb_funcall(rb_funcall(arg1, rb_intern(\"*\"), 1, arg2), rb_intern(\"*\"), 1, LONG2NUM(7));
rb_funcall(self, rb_intern(\"puts\"), 1, rb_funcall(arg3, rb_intern(\"to_s\"), 0));
return rb_str_new2(\"foo\");
}",
            "RubyToAnsiC" => "str
multi_args(long arg1, long arg2) {
long arg3;
arg3 = arg1 * arg2 * 7;
puts(to_s(arg3));
return \"foo\";
}")

  add_tests("next",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("next_arg",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("not",
            "Rewriter"    => :same,
            "TypeChecker" => t(:not, t(:true, Type.bool), Type.bool),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "!(1)",
            "RubyToRubyC" => "!(Qtrue)")

  add_tests("nth_ref",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("op_asgn1",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("op_asgn1_ivar",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("op_asgn2",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("op_asgn2_self",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("op_asgn_and",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("op_asgn_and_ivar2",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("op_asgn_or",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("op_asgn_or_block",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("op_asgn_or_ivar",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("op_asgn_or_ivar2",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("or",
            "Rewriter"    => :same,
            "TypeChecker" => t(:or,
                               t(:call, nil, :a, t(:arglist), Type.bool),
                               t(:call, nil, :b, t(:arglist), Type.bool),
                               Type.bool),
            "CRewriter"   => :same,
            "RubyToAnsiC" => 'a() || b()',
            "RubyToRubyC" => 'rb_funcall(self, rb_intern("a"), 0) || rb_funcall(self, rb_intern("b"), 0)')

  add_tests("or_big",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("or_big2",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("parse_floats_as_args",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("postexe",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("proc_args_0",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("proc_args_1",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("proc_args_2",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("proc_args_no",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("redo",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("rescue",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("rescue_block_body",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("rescue_block_nada",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("rescue_exceptions",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("retry",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("return_0",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("return_1",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("return_n",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("sclass",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("sclass_trailing_class",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("splat",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("str",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("str_concat_newline",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("str_concat_space",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("str_heredoc",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("str_heredoc_call",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("str_heredoc_double",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("str_heredoc_indent",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("str_interp_file",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("structure_extra_block_for_dvar_scoping",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("structure_remove_begin_1",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("structure_remove_begin_2",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("structure_unused_literal_wwtt",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("super",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("super_block_pass",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("super_block_splat",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("super_multi",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("svalue",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("to_ary",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("true",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("undef",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("undef_2",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("undef_3",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("undef_block_1",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("undef_block_2",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("undef_block_3",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("undef_block_3_post",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("undef_block_wtf",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("until_post",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("until_post_not",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("until_pre",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("until_pre_mod",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("until_pre_not",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("until_pre_not_mod",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("valias",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("vcall",
            "Rewriter"    => :same,
            "TypeChecker" => t(:call, nil, :method, t(:arglist), Type.unknown),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "method()",
            "RubyToRubyC" => "rb_funcall(self, rb_intern(\"method\"), 0)")

  add_tests("while_post",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("while_post2",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("while_post_not",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("while_pre",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("while_pre_mod",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("while_pre_nil",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("while_pre_not",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("while_pre_not_mod",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("whiles", # TODO: not in pttc
            "Ruby"        => "def whiles
                                while false do
                                  puts \"false\"
                                end
                                begin
                                  puts \"true\"
                                end while false
                              end",
            "ParseTree"   => s(:defn,
                               :whiles,
                               s(:args),
                               s(:scope,
                                 s(:block,
                                   s(:while, s(:false),
                                     s(:call, nil, :puts,
                                       s(:arglist, s(:str, "false"))),
                                     true),
                                   s(:while, s(:false),
                                     s(:call, nil, :puts,
                                       s(:arglist, s(:str, "true"))),
                                     false)))),
            "Rewriter"    => :same,
            "TypeChecker" => t(:defn,
                               :whiles,
                               t(:args),
                               t(:scope,
                                 t(:block,
                                   t(:while,
                                     t(:false, Type.bool),
                                     t(:call,
                                       nil,
                                       :puts,
                                       t(:arglist, t(:str, "false", Type.str)), Type.void),
                                     true),
                                   t(:while,
                                     t(:false, Type.bool),
                                     t(:call,
                                       nil,
                                       :puts,
                                       t(:arglist, t(:str, "true", Type.str)), Type.void),
                                     false),
                                   Type.unknown),
                                 Type.void),
                               Type.function(Type.unknown, [], Type.void)),
            "CRewriter"   => :same,
            "RubyToAnsiC" => "void\nwhiles() {\nwhile (0) {\nputs(\"false\");\n};\n{\nputs(\"true\");\n} while (0);\n}",
            "RubyToRubyC" => "static VALUE\nrrc_c_whiles(VALUE self) {\nwhile (Qfalse) {\nrb_funcall(self, rb_intern(\"puts\"), 1, rb_str_new2(\"false\"));\n};\n{\nrb_funcall(self, rb_intern(\"puts\"), 1, rb_str_new2(\"true\"));\n} while (Qfalse);\n}")

  add_tests("xstr",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("yield_0",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("yield_1",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("yield_n",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)

  add_tests("zarray",
            "Rewriter"    => :same,
            "TypeChecker" => t(:lasgn, :a, t(:array), Type.unknown_list),
            "CRewriter"   => :same,
            # TODO: need to verify that our variable decl will be correct
            "RubyToAnsiC" => "a = (void *) malloc(sizeof(void *) * 0)",
            "RubyToRubyC" => "a = rb_ary_new2(0)")

  add_tests("zsuper",
            "Rewriter"    => :same,
            "TypeChecker" => :skip,
            "CRewriter"   => :skip,
            "RubyToAnsiC" => :skip,
            "RubyToRubyC" => :skip)
end
