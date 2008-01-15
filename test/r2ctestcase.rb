require 'test/unit/testcase'
require 'sexp_processor' # for deep_clone FIX
require 'typed_sexp'
require 'unique'

# TODO: str -> char * in ansi c
# TODO: add tests that mix types up to fuck up RubyC type checker

class R2CTestCase < Test::Unit::TestCase

  attr_accessor :processor # to be defined by subclass

  def self.testcase_order; @@testcase_order; end
  def self.testcases; @@testcases; end

  def setup
    super
    @processor = nil
    Unique.reset
  end

  @@testcase_order = %w(Ruby ParseTree Rewriter TypeChecker CRewriter RubyToAnsiC RubyToRubyC)

  @@testcases = {

    "accessor" => {
      "TypeChecker" => :skip,
      "CRewriter"   => :skip,
      "RubyToAnsiC" => :skip,
      "RubyToRubyC" => :skip,
    },

    "accessor_equals" => {
      "TypeChecker" => :skip,
      "CRewriter"   => :skip,
      "RubyToRubyC" => :skip,
      "RubyToAnsiC" => :skip,
    },

    "defn_bbegin" => {
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
      "CRewriter" => :same,
      "RubyToRubyC" => :unsupported,
      "RubyToAnsiC" => :unsupported,
    },

    "bools" => {
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
                         Type.function(Type.unknown, [Type.value], Type.bool)),
      "CRewriter" => :same,
      "RubyToRubyC"     => "static VALUE\nrrc_c_bools(VALUE self, VALUE arg1) {\nif (NIL_P(arg1)) {\nreturn Qfalse;\n} else {\nreturn Qtrue;\n}\n}",
      "RubyToAnsiC"     => "bool\nbools(void * arg1) {\nif (arg1) {\nreturn 0;\n} else {\nreturn 1;\n}\n}",
    },

# TODO: move all call tests here
    "call_arglist"  => {
      "TypeChecker" => :skip,
      "CRewriter" => :skip,
      "RubyToRubyC" => :skip,
      "RubyToAnsiC" => :skip,
    },

    "call_attrasgn" => {
      "TypeChecker" => :skip,
      "CRewriter" => :skip,
      "RubyToRubyC" => :skip,
      "RubyToAnsiC" => :skip,
    },

    "call_self" => {
      "TypeChecker" => :skip,
      "CRewriter" => :skip,
      "RubyToRubyC" => :skip,
      "RubyToAnsiC" => :skip,
    },

    "case_stmt" => {
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
      "CRewriter" => :same,
# HACK: I don't like the semis after the if blocks, but it is a compromise right now
      "RubyToRubyC" => "static VALUE
rrc_c_case_stmt(VALUE self) {
VALUE result;
VALUE var;
var = LONG2NUM(2);
result = rb_str_new2(\"\");
if (rb_funcall(var, rb_intern(\"===\"), 1, LONG2NUM(1))) {
rb_funcall(self, rb_intern(\"puts\"), 1, rb_str_new2(\"something\"));
result = rb_str_new2(\"red\");
} else {
if (rb_funcall(var, rb_intern(\"===\"), 1, LONG2NUM(2)) || rb_funcall(var, rb_intern(\"===\"), 1, LONG2NUM(3))) {
result = rb_str_new2(\"yellow\");
} else {
if (rb_funcall(var, rb_intern(\"===\"), 1, LONG2NUM(4))) {
;
} else {
result = rb_str_new2(\"green\");
}
}
};
if (rb_funcall(result, rb_intern(\"===\"), 1, rb_str_new2(\"red\"))) {
var = LONG2NUM(1);
} else {
if (rb_funcall(result, rb_intern(\"===\"), 1, rb_str_new2(\"yellow\"))) {
var = LONG2NUM(2);
} else {
if (rb_funcall(result, rb_intern(\"===\"), 1, rb_str_new2(\"green\"))) {
var = LONG2NUM(3);
}
}
};
return result;
}",
      "RubyToAnsiC" => "str
case_stmt() {
str result;
long var;
var = 2;
result = \"\";
if (case_equal_long(var, 1)) {
puts(\"something\");
result = \"red\";
} else {
if (case_equal_long(var, 2) || case_equal_long(var, 3)) {
result = \"yellow\";
} else {
if (case_equal_long(var, 4)) {
;
} else {
result = \"green\";
}
}
};
if (case_equal_str(result, \"red\")) {
var = 1;
} else {
if (case_equal_str(result, \"yellow\")) {
var = 2;
} else {
if (case_equal_str(result, \"green\")) {
var = 3;
}
}
};
return result;
}",
    },

    "conditional1" => {
      "TypeChecker" => t(:if,
                         t(:call, t(:lit, 42, Type.long), :==,
                           t(:arglist, t(:lit, 0, Type.long)),
                           Type.bool),
                         t(:return, t(:lit, 1, Type.long), Type.void),
                         nil,
                         Type.void),
      "CRewriter" => t(:if,
                         t(:call, t(:lit, 42, Type.long), :==,
                           t(:arglist, t(:lit, 0, Type.long)),
                           Type.bool),
                         t(:return, t(:lit, 1, Type.long), Type.void),
                         nil,
                         Type.void),
      "RubyToRubyC" => "if (rb_funcall(LONG2NUM(42), rb_intern(\"==\"), 1, LONG2NUM(0))) {\nreturn LONG2NUM(1);\n}",
      "RubyToAnsiC" => "if (42 == 0) {\nreturn 1;\n}",
    },

    "conditional2" => {
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
      "CRewriter" => :same,
      "RubyToRubyC" => "if (rb_funcall(LONG2NUM(42), rb_intern(\"==\"), 1, LONG2NUM(0))) {\n;\n} else {\nreturn LONG2NUM(2);\n}",
      "RubyToAnsiC" => "if (42 == 0) {\n;\n} else {\nreturn 2;\n}",
    },

    "conditional3" => {
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
      "CRewriter" => :same,
      "RubyToRubyC" => "if (rb_funcall(LONG2NUM(42), rb_intern(\"==\"), 1, LONG2NUM(0))) {\nreturn LONG2NUM(3);\n} else {\nreturn LONG2NUM(4);\n}",
      "RubyToAnsiC" => "if (42 == 0) {\nreturn 3;\n} else {\nreturn 4;\n}",
    },

    "conditional4" => {
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
      "CRewriter" => :same,
      "RubyToRubyC" => "if (rb_funcall(LONG2NUM(42), rb_intern(\"==\"), 1, LONG2NUM(0))) {\nreturn LONG2NUM(2);\n} else {\nif (rb_funcall(LONG2NUM(42), rb_intern(\"<\"), 1, LONG2NUM(0))) {\nreturn LONG2NUM(3);\n} else {\nreturn LONG2NUM(4);\n}\n}",
      "RubyToAnsiC" => "if (42 == 0) {\nreturn 2;\n} else {\nif (42 < 0) {\nreturn 3;\n} else {\nreturn 4;\n}\n}",
    },

    "defn_bmethod_added" => {
      "TypeChecker" => :skip,
      "CRewriter" => :skip,
      "RubyToRubyC" => :skip,
      "RubyToAnsiC" => :skip,
    },

    "defn_empty" => {
      "TypeChecker" => t(:defn, :empty,
                         t(:args),
                         t(:scope,
                           t(:block,
                             t(:nil, Type.value),
                             Type.unknown),
                           Type.void),
                         Type.function(Type.unknown, [], Type.void)),
      "CRewriter" => :same,
      "RubyToRubyC" => "static VALUE\nrrc_c_empty(VALUE self) {\nQnil;\n}",
      "RubyToAnsiC" => "void\nempty() {\nNULL;\n}",
    },

    "defn_zarray" => {
      "TypeChecker" => t(:defn,
                         :empty,
                         t(:args),
                         t(:scope,
                           t(:block,
                             t(:lasgn, :a, t(:array), Type.unknown_list),
                             t(:return,
                               t(:lvar,
                                 :a, Type.unknown_list), Type.void),
                             Type.unknown), Type.void),
                         Type.function(Type.unknown, [], Type.unknown_list)),
      "CRewriter" => :same,
      "RubyToRubyC" => "static VALUE\nrrc_c_empty(VALUE self) {\nVALUE a;\na = rb_ary_new2(0);\nreturn a;\n}",
      "RubyToAnsiC" => "void *\nempty() {\nvoid * a;\na = (void *) malloc(sizeof(void *) * 0);\nreturn a;\n}",
    },

    "defn_or" => {
      "TypeChecker" => t(:defn, :|,
                         t(:args),
                         t(:scope,
                           t(:block,
                             t(:nil, Type.value),
                             Type.unknown),
                           Type.void),
                         Type.function(Type.unknown, [], Type.void)),
      "CRewriter" => :same,
      "RubyToRubyC" => "static VALUE\nrrc_c_or(VALUE self) {\nQnil;\n}",
      "RubyToAnsiC" => "void\nor() {\nNULL;\n}",
    },

    "defn_is_something" => {
      "TypeChecker" => t(:defn, :something?,
                         t(:args),
                         t(:scope,
                           t(:block,
                             t(:nil, Type.value),
                             Type.unknown),
                           Type.void),
                         Type.function(Type.unknown, [], Type.void)),
      "CRewriter" => :same,
      "RubyToRubyC" => "static VALUE\nrrc_c_is_something(VALUE self) {\nQnil;\n}",
      "RubyToAnsiC" => "void\nis_something() {\nNULL;\n}",
    },

    "defn_fbody" => {
      "TypeChecker" => :skip,
      "CRewriter" => :skip,
      "RubyToRubyC" => :skip,
      "RubyToAnsiC" => :skip,
    },

    "defn_optargs" => {
      "TypeChecker" => :skip,
      "CRewriter" => :skip,
      "RubyToRubyC" => :skip,
      "RubyToAnsiC" => :skip,
    },

    "dmethod_added" => {
      "TypeChecker" => :skip,
      "CRewriter" => :skip,
      "RubyToRubyC" => :skip,
      "RubyToAnsiC" => :skip,
    },

    "global" => {
      # TODO: test s(:gvar, :$stderr) != t(:gvar, $stderr, Type.file)
      "TypeChecker" => t(:gvar, :$stderr, Type.file),
      "CRewriter" => :same,
      "RubyToRubyC" => "rb_gv_get(\"$stderr\")",
      "RubyToAnsiC" => "stderr",
    },

    "interpolated" => {
      "TypeChecker" => t(:dstr,
                         "var is ",
                             t(:lvar, :argl, Type.long),
                             t(:str, ". So there.", Type.str),
                             Type.str),
      "CRewriter" => :same,
      "RubyToRubyC" => "rb_funcall(rb_mKernel, rb_intern(\"sprintf\"), 4, rb_str_new2(\"%s%s%s\"), rb_str_new2(\"var is \"), argl, rb_str_new2(\". So there.\"))",
      "RubyToAnsiC" => :unsupported,
    },

    "iter" => {
      "TypeChecker" => t(:iter,
                         t(:call, nil, :loop, nil, Type.unknown),
                         t(:dasgn_curr, :temp_1, Type.unknown),
                         nil,
                         Type.unknown),
      "CRewriter" => :skip, # HACK don't do rb_iterate stuff for loop
#      "CRewriter" => [:defx,
#                      t(:iter,
#                       t(:call, nil, :loop, nil, Type.unknown),
#                       t(:args,
#                         t(:array, t(:dasgn_curr, :temp_1, Type.unknown), Type.void),
#                         t(:array, Type.void), Type.void),
#                        t(:call, nil, :temp_1, nil)),
#                      [t(:defx,
#                         :temp_2,
#                         t(:args, :temp_2, :temp_3),
#                         t(:scope, t(:block, nil)), Type.void)]],
      "RubyToRubyC" => "",
      "RubyToAnsiC" => "",
    },

    "iteration2" => {
      "TypeChecker" => t(:iter,
                         t(:call,
                           t(:lvar, :arrays, Type.str_list),
                           :each,
                           nil, Type.unknown),
                         t(:dasgn_curr, :x, Type.str),
                         t(:call, nil, :puts,
                           t(:arglist, t(:dvar, :x, Type.str)),
                           Type.void),
                         Type.void),
       "CRewriter" => [:defx,
                       t(:iter,
                         t(:call,
                           t(:lvar, :arrays, Type.str_list),
                           :each,
                           nil, Type.unknown),
                         t(:args,
                           t(:array, t(:lvar, :arrays, Type.value), Type.void),
                           t(:array, t(:lvar, :static_temp_4, Type.value), Type.void),
                           Type.void),
                         :temp_1),
                       [t(:static, "static VALUE static_temp_4;", Type.fucked),
                        t(:defx,
                          :temp_1,
                          t(:args,
                            t(:temp_2, Type.str),
                            t(:temp_3, Type.value)),
                          t(:scope,
                            t(:block,
                              t(:lasgn,
                                :arrays,
                                t(:lvar, :static_temp_4, Type.value),
                                Type.value),
                              t(:lasgn, :x, t(:lvar, :temp_2, Type.str),
                                Type.str),
                              t(:call,
                                nil,
                                :puts,
                                t(:arglist, t(:dvar, :x, Type.str)), Type.void),
                              t(:lasgn,
                                :static_temp_4,
                                t(:lvar, :arrays, Type.value),
                                Type.value),
                              t(:return, t(:nil, Type.value)))), Type.void)]],
      "RubyToAnsiC" => :skip, # because eric sucks soooo much
                         # 'unsigned long index_x;
                         # for (index_x = 0; arrays[index_x] != NULL; ++index_x) {
                         # str x = arrays[index_x];
                         # puts(x);
                         # }',
      "RubyToRubyC" => [:defx,
                        "static_temp_4 = arrays;
rb_iterate(rb_each, arrays, temp_1, Qnil);
arrays = static_temp_4;",
                        ["static VALUE static_temp_4;",
"static VALUE
rrc_c_temp_1(VALUE temp_2, VALUE temp_3) {
VALUE arrays;
VALUE x;
arrays = static_temp_4;
x = temp_2;
rb_funcall(self, rb_intern(\"puts\"), 1, x);
static_temp_4 = arrays;
return Qnil;
}"]]
    },


    "iteration4" => {
      "TypeChecker" => t(:dummy, t(:lasgn, :n, t(:lit, 1, Type.long), Type.long),
                         t(:while,
                           t(:call,
                             t(:lvar, :n, Type.long),
                             :<=,
                             t(:arglist, t(:lit, 3, Type.long)), Type.bool),
                           t(:block,
                             t(:call, nil, :puts,
                               t(:arglist,
                                 t(:call,
                                   t(:lvar, :n, Type.long),
                                   :to_s,
                                   nil, Type.str)), Type.void),
                             t(:lasgn, :n,
                               t(:call,
                                 t(:lvar, :n, Type.long),
                                 :+,
                                 t(:arglist,
                                   t(:lit,
                                     1, Type.long)),
                                 Type.long), Type.long), Type.unknown), true)),
      "CRewriter" => :same,
      "RubyToAnsiC" => 'n = 1;
while (n <= 3) {
puts(to_s(n));
n = n + 1;
}',
      "RubyToRubyC" => 'n = LONG2NUM(1);
while (rb_funcall(n, rb_intern("<="), 1, LONG2NUM(3))) {
rb_funcall(self, rb_intern("puts"), 1, rb_funcall(n, rb_intern("to_s"), 0));
n = rb_funcall(n, rb_intern("+"), 1, LONG2NUM(1));
}',
    },

    "iteration5" => {
      "TypeChecker" => t(:dummy,
                         t(:lasgn, :n, t(:lit, 3, Type.long), Type.long),
                         t(:while,
                           t(:call,
                             t(:lvar, :n, Type.long),
                             :>=,
                             t(:arglist, t(:lit, 1, Type.long)), Type.bool),
                           t(:block,
                             t(:call, nil, :puts,
                               t(:arglist,
                                 t(:call,
                                   t(:lvar, :n, Type.long),
                                   :to_s,
                                   nil, Type.str)), Type.void),
                             t(:lasgn, :n,
                               t(:call,
                                 t(:lvar, :n, Type.long),
                                 :-,
                                 t(:arglist, t(:lit, 1, Type.long)),
                                 Type.long),
                               Type.long),
                           Type.unknown), true)),
      "CRewriter" => :same,
      "RubyToAnsiC" => 'n = 3;
while (n >= 1) {
puts(to_s(n));
n = n - 1;
}',
      "RubyToRubyC" => 'n = LONG2NUM(3);
while (rb_funcall(n, rb_intern(">="), 1, LONG2NUM(1))) {
rb_funcall(self, rb_intern("puts"), 1, rb_funcall(n, rb_intern("to_s"), 0));
n = rb_funcall(n, rb_intern("-"), 1, LONG2NUM(1));
}',
    },

    "iteration6" => {
      "TypeChecker" => t(:while,
                         t(:call, t(:lvar, :argl, Type.long),
                           :>=,
                           t(:arglist, t(:lit, 1, Type.long)), Type.bool),
                         t(:block,
                           t(:call, nil, :puts,
                             t(:arglist, t(:str, "hello", Type.str)),
                             Type.void),
                           t(:lasgn,
                             :argl,
                             t(:call, t(:lvar, :argl, Type.long),
                               :-,
                               t(:arglist, t(:lit, 1, Type.long)), Type.long),
                             Type.long),
                           Type.unknown), true),
      "CRewriter" => :same,
      "RubyToAnsiC" => 'while (argl >= 1) {
puts("hello");
argl = argl - 1;
}',
      "RubyToRubyC" => 'while (rb_funcall(argl, rb_intern(">="), 1, LONG2NUM(1))) {
rb_funcall(self, rb_intern("puts"), 1, rb_str_new2("hello"));
argl = rb_funcall(argl, rb_intern("-"), 1, LONG2NUM(1));
}',
    },

    # TODO: this might still be too much
    "lasgn_call" => {
      "TypeChecker" => t(:lasgn, :c,
                         t(:call,
                           t(:lit, 2, Type.long),
                           :+,
                           t(:arglist,
                             t(:lit, 3, Type.long)),
                           Type.long),
                         Type.long),
      "CRewriter" => :same,
      "RubyToRubyC" => 'c = rb_funcall(LONG2NUM(2), rb_intern("+"), 1, LONG2NUM(3))', # FIX: probably not "c ="
      "RubyToAnsiC" => "c = 2 + 3",
    },

    "lasgn_array" => {
      "TypeChecker" => t(:lasgn,
                         :var,
                         t(:array,
                           t(:str, "foo", Type.str),
                           t(:str, "bar", Type.str)),
                         Type.str_list),
      "CRewriter" => :same,
      "RubyToRubyC" => 'var = rb_ary_new2(2);
rb_ary_store(var, 0, rb_str_new2("foo"));
rb_ary_store(var, 1, rb_str_new2("bar"))',
      "RubyToAnsiC" => 'var = (str) malloc(sizeof(str) * 2);
var[0] = "foo";
var[1] = "bar"'
},

    "lit_bool_false" => {
      "TypeChecker" => t(:false, Type.bool),
      "CRewriter" => :same,
      "RubyToRubyC" => "Qfalse",
      "RubyToAnsiC" => "0",
    },

    "lit_bool_true" => {
      "TypeChecker" => t(:true, Type.bool),
      "CRewriter" => :same,
      "RubyToRubyC" => "Qtrue",
      "RubyToAnsiC" => "1",
    },

    "lit_float" => {
      "TypeChecker" => t(:lit, 1.1, Type.float),
      "CRewriter" => :same,
      "RubyToRubyC" => "rb_float_new(1.1)",
      "RubyToAnsiC" => "1.1",
    },

    "lit_long" => {
      "TypeChecker" => t(:lit, 1, Type.long),
      "CRewriter" => :same,
      "RubyToRubyC" => "LONG2NUM(1)",
      "RubyToAnsiC" => "1",
    },

    "lit_sym" => {
      "TypeChecker" => t(:lit, :x, Type.symbol),
      "CRewriter" => :same,
      "RubyToRubyC" => 'ID2SYM(rb_intern("x"))',
      "RubyToAnsiC" => '"x"', # HACK WRONG! (or... is it?)
    },

    "lit_str" => {
      "TypeChecker" => t(:str, "x", Type.str),
      "CRewriter" => :same,
      "RubyToRubyC" => 'rb_str_new2("x")',
      "RubyToAnsiC" => '"x"',
    },

    "multi_args" => {
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
                             t(:arglist,
                               t(:lvar,
                                 :arg2,
                                 Type.long)),
                             Type.long),
                           :*,
                           t(:arglist,
                             t(:lit, 7, Type.long)),
                           Type.long),
                         Type.long),
                       t(:call,
                         nil,
                         :puts,
                         t(:arglist,
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
                   Type.function(Type.unknown,
                                 [Type.long, Type.long], Type.str)),
      "CRewriter" => :same,
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
}",
    },
 
    "vcall" => {
      "TypeChecker" => t(:call, nil, :method, nil, Type.unknown),
      "CRewriter" => :same,
      "RubyToRubyC" => "rb_funcall(self, rb_intern(\"method\"), 0)",
      "RubyToAnsiC" => "method()",
    },

    "whiles" => {
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
      "CRewriter" => :same,
      "RubyToRubyC" => "static VALUE
rrc_c_whiles(VALUE self) {
while (Qfalse) {
rb_funcall(self, rb_intern(\"puts\"), 1, rb_str_new2(\"false\"));
};
{
rb_funcall(self, rb_intern(\"puts\"), 1, rb_str_new2(\"true\"));
} while (Qfalse);
}",
      "RubyToAnsiC" => "void
whiles() {
while (0) {
puts(\"false\");
};
{
puts(\"true\");
} while (0);
}",
    },

    "zarray" => {
      "TypeChecker" => t(:lasgn, :a, t(:array), Type.unknown_list),
      "CRewriter" => :same,
      # TODO: need to verify that our variable decl will be correct
      "RubyToRubyC" => "a = rb_ary_new2(0)",
      "RubyToAnsiC" => "a = (void *) malloc(sizeof(void *) * 0)",
    },
  }

  def self.previous(key)
    idx = @@testcase_order.index(key)-1
    case key
    when "RubyToRubyC" then
      idx -= 1
    end
    @@testcase_order[idx]
  end

  # lets us used unprocessed :self outside of tests, called when subclassed
  def self.clone_same
    @@testcases.each do |node, data|
      data.each do |key, val|
        if val == :same then
          prev_key = self.previous(key)
          data[key] = data[prev_key].deep_clone
        end
      end
    end
  end

  def self.inherited(c)
    self.clone_same

    output_name = c.name.to_s.sub(/^Test/, '')
    raise "Unknown class #{c}" unless @@testcase_order.include? output_name

    input_name = self.previous(output_name)

    @@testcases.each do |node, data|
      next if data[input_name] == :skip
      next if data[output_name] == :skip

      c.send(:define_method, "test_#{node}".intern) do
        flunk "Processor is nil" if processor.nil?
        assert data.has_key?(input_name), "Unknown input data"
        assert data.has_key?(output_name), "Unknown expected data"
        input = data[input_name].deep_clone
        expected = data[output_name].deep_clone

        case expected
        when :unsupported then
          assert_raises(UnsupportedNodeError) do
            processor.process(input)
          end
        else
          extra_expected = []
          extra_input = []

          _, expected, extra_expected = *expected if Array === expected and expected.first == :defx
          _, input, extra_input = *input if Array === input and input.first == :defx
          
          assert_equal expected, processor.process(input)

          if processor.respond_to? :extra_methods then
            assert_equal extra_expected, processor.extra_methods
          end

          extra_expected.zip extra_input do |expected, input|
            assert_equal expected, processor.process(input)
          end unless extra_input.empty?
        end
      end
    end
  end

  def test_stoopid
    # do nothing - shuts up empty test class requirement
  end

end
