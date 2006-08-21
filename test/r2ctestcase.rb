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
      "Ruby"        => "attr_reader :accessor",
      "ParseTree"   => [:defn, :accessor, [:ivar, :@accessor]],
      "Rewriter"    => s(:defn, :accessor, s(:args),
                         s(:scope,
                           s(:block, s(:return, s(:ivar, :@accessor))))),
      "TypeChecker" => :skip,
      "CRewriter"   => :skip,
      "RubyToAnsiC" => :skip,
      "RubyToRubyC" => :skip,
    },

    "accessor_equals" => {
      "Ruby"        => "attr_writer :accessor",
      "ParseTree"   => [:defn, :accessor=, [:attrset, :@accessor]],
      "Rewriter"    => s(:defn,
                        :accessor=,
                        s(:args, :arg),
                        s(:scope,
                          s(:block,
                            s(:return,
                              s(:iasgn, :@accessor, s(:lvar, :arg)))))),
      "TypeChecker" => :skip,
      "CRewriter"   => :skip,
      "RubyToRubyC" => :skip,
      "RubyToAnsiC" => :skip,
    },

    "defn_bbegin" => {
      "Ruby"        => "def bbegin()
  begin
    1 + 1
  rescue SyntaxError
    e1 = $!
    2
  rescue Exception
    e2 = $!
    3
  else
    4end
  ensure
    5
end",
     "ParseTree"   => [:defn, :bbegin,
       [:scope,
         [:block,
           [:args],
           [:begin,
             [:ensure,
               [:rescue,
                 [:call, [:lit, 1], :+, [:array, [:lit, 1]]],
                 [:resbody,
                   [:array, [:const, :SyntaxError]],
                   [:block, [:lasgn, :e1, [:gvar, :$!]], [:lit, 2]],
                   [:resbody,
                     [:array, [:const, :Exception]],
                     [:block, [:lasgn, :e2, [:gvar, :$!]], [:lit, 3]]]],
                 [:lit, 4]],
               [:lit, 5]]]]]],
      "Rewriter" => s(:defn, :bbegin,
               s(:args),
               s(:scope,
                 s(:block,
                   s(:begin,
                     s(:ensure,
                       s(:rescue,
                         s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))),
                         s(:resbody,
                           s(:array, s(:const, :SyntaxError)),
                           s(:block, s(:lasgn, :e1, s(:gvar, :$!)),
                             s(:lit, 2)),
                           s(:resbody,
                             s(:array, s(:const, :Exception)),
                             s(:block, s(:lasgn, :e2, s(:gvar, :$!)),
                               s(:lit, 3)))),
                         s(:lit, 4)),
                       s(:lit, 5)))))),
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
      "Ruby"      => "def bools(arg1)
  if (arg1.nil?)
    return false
  else
    return true
  end
end",
      "ParseTree" => [:defn, :bools,
        [:scope,
          [:block,
            [:args, :arg1],
            [:if,
              [:call, [:lvar, :arg1], "nil?".intern], # emacs is freakin'
              [:return, [:false]],
              [:return, [:true]]]]]],
      "Rewriter" => s(:defn, :bools,
              s(:args, :arg1),
              s(:scope,
                s(:block,
                  s(:if,
                    s(:call,
                      s(:lvar, :arg1),
                      :nil?,
                      nil),
                    s(:return, s(:false)),
                    s(:return, s(:true)))))),
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
      "Ruby"        => "puts(42)",
      "ParseTree"   => [:fcall,      :puts,  [:array,    [:lit, 42]]],
      "Rewriter"    => s(:call, nil, :puts, s(:arglist, s(:lit, 42))),
      "TypeChecker" => :skip,
      "CRewriter" => :skip,
      "RubyToRubyC" => :skip,
      "RubyToAnsiC" => :skip,
    },

    "call_attrasgn" => {
      "Ruby"        => "42.method=(y)",
      "ParseTree"   => [:attrasgn, [:lit, 42], :method=, [:array, [:lvar, :y]]],
      "Rewriter"    => s(:call,   s(:lit, 42), :method=, s(:arglist, s(:lvar, :y))),
      "TypeChecker" => :skip,
      "CRewriter" => :skip,
      "RubyToRubyC" => :skip,
      "RubyToAnsiC" => :skip,
    },

    "call_self" => {
      "Ruby"        => "self.method",
      "ParseTree" => [:call, [:self], :method],
      "Rewriter"  => s(:call, s(:lvar, :self), :method, nil),
      "TypeChecker" => :skip,
      "CRewriter" => :skip,
      "RubyToRubyC" => :skip,
      "RubyToAnsiC" => :skip,
    },

    "case_stmt" => {
      "Ruby"        => "
def case_stmt()
  var = 2
  result = \"\"
  case var
  when 1
    puts(\"something\")
    result = \"red\"
  when 2, 3
    result = \"yellow\"
  when 4
  else
    result = \"green\"
  end
  case result
  when \"red\"
    var = 1
  when \"yellow\"
    var = 2
  when \"green\"
    var = 3
  else
  end
  return result
end",
      "ParseTree" => [:defn, :case_stmt,
   [:scope,
    [:block,
     [:args],
     [:lasgn, :var, [:lit, 2]],
     [:lasgn, :result, [:str, ""]],
     [:case,
      [:lvar, :var],
      [:when,
       [:array, [:lit, 1]],
       [:block,
        [:fcall, :puts, [:array, [:str, "something"]]],
        [:lasgn, :result, [:str, "red"]]]],
      [:when,
       [:array, [:lit, 2], [:lit, 3]],
       [:lasgn, :result, [:str, "yellow"]]],
      [:when, [:array, [:lit, 4]], nil],
      [:lasgn, :result, [:str, "green"]]],
     [:case,
      [:lvar, :result],
      [:when, [:array, [:str, "red"]], [:lasgn, :var, [:lit, 1]]],
      [:when, [:array, [:str, "yellow"]], [:lasgn, :var, [:lit, 2]]],
      [:when, [:array, [:str, "green"]], [:lasgn, :var, [:lit, 3]]],
      nil],
     [:return, [:lvar, :result]]]]],
      "Rewriter" => s(:defn, :case_stmt,
                  s(:args),
                  s(:scope,
                    s(:block,
                      s(:lasgn, :var, s(:lit, 2)),
                      s(:lasgn, :result, s(:str, "")),
                      s(:if,
                        s(:call,
                          s(:lvar, :var),
                          :===,
                          s(:arglist, s(:lit, 1))),
                        s(:block,
                          s(:call,
                            nil,
                            :puts,
                            s(:arglist, s(:str, "something"))),
                          s(:lasgn, :result, s(:str, "red"))),
                        s(:if,
                          s(:or,
                            s(:call,
                              s(:lvar, :var),
                              :===,
                              s(:arglist, s(:lit, 2))),
                            s(:call,
                              s(:lvar, :var),
                              :===,
                              s(:arglist, s(:lit, 3)))),
                          s(:lasgn, :result, s(:str, "yellow")),
                          s(:if,
                            s(:call,
                              s(:lvar, :var),
                              :===,
                              s(:arglist, s(:lit, 4))),
                            nil,
                            s(:lasgn, :result, s(:str, "green"))))),
                      s(:if,
                        s(:call,
                          s(:lvar, :result),
                          :===,
                          s(:arglist, s(:str, "red"))),
                        s(:lasgn, :var, s(:lit, 1)),
                        s(:if,
                          s(:call,
                            s(:lvar, :result),
                            :===,
                            s(:arglist, s(:str, "yellow"))),
                          s(:lasgn, :var, s(:lit, 2)),
                          s(:if,
                            s(:call,
                              s(:lvar, :result),
                              :===,
                              s(:arglist, s(:str, "green"))),
                            s(:lasgn, :var, s(:lit, 3)),
                            nil))),
                      s(:return, s(:lvar, :result))))),
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
      "Ruby"        => "if (42 == 0)\n  return 1\n\nend",
      "ParseTree"   => [:if, [:call, [:lit, 42], :==, [:array, [:lit, 0]]], [:return, [:lit, 1]], nil],
      "Rewriter"    => s(:if, s(:call, s(:lit, 42), :==, s(:arglist, s(:lit, 0))), s(:return, s(:lit, 1)), nil),
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
      "Ruby"        => "unless (42 == 0)\n  return 2\nend",
      "ParseTree"   => [:if, [:call, [:lit, 42], :==, [:array, [:lit, 0]]], nil, [:return, [:lit, 2]]],
      "Rewriter"    => s(:if,
                         s(:call, s(:lit, 42),
                           :==, s(:arglist, s(:lit, 0))),
                         nil,
                         s(:return, s(:lit, 2))),
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
      "Ruby"        => "if (42 == 0)\n  return 3\nelse\n  return 4\nend",
      "ParseTree"   => [:if, [:call, [:lit, 42], :==, [:array, [:lit, 0]]],
        [:return, [:lit, 3]],
        [:return, [:lit, 4]]],
      "Rewriter"    => s(:if,
                         s(:call,
                           s(:lit, 42),
                           :==,
                           s(:arglist, s(:lit, 0))),
                         s(:return, s(:lit, 3)),
                         s(:return, s(:lit, 4))),
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
      "Ruby"        => "if (42 == 0)
  return 2
else
  if (42 < 0)
    return 3
  else
    return 4
  end
end",
      "ParseTree"   => [:if,
        [:call, [:lit, 42], :==, [:array, [:lit, 0]]],
        [:return, [:lit, 2]],
        [:if,
          [:call, [:lit, 42], :<, [:array, [:lit, 0]]],
          [:return, [:lit, 3]],
          [:return, [:lit, 4]]]],
      "Rewriter"    => s(:if,
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
                           s(:return, s(:lit, 4)))),
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
      "Ruby"        => "def bmethod_added(x)\n  x + 1\nend",
      "ParseTree"   => [:defn, :bmethod_added,
        [:bmethod,
          [:dasgn_curr, :x],
          [:call, [:dvar, :x], :+, [:array, [:lit, 1]]]]],
      "Rewriter" => s(:defn,
                      :bmethod_added,
                      s(:args, :x),
                      s(:scope,
                        s(:block,
                          s(:call, s(:lvar, :x), :+, s(:arglist, s(:lit, 1)))))),
      "TypeChecker" => :skip,
      "CRewriter" => :skip,
      "RubyToRubyC" => :skip,
      "RubyToAnsiC" => :skip,
    },

    "defn_empty" => {
      "Ruby"        => "def empty()\n  nil\nend",
      "ParseTree"   => [:defn, :empty, [:scope, [:block, [:args], [:nil]]]],
      "Rewriter"    => s(:defn, :empty,
                         s(:args), s(:scope, s(:block, s(:nil)))),
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
      "Ruby"        => "def empty()\n  a = []\n  return a\nend",
      "ParseTree"   => [:defn, :empty, [:scope, [:block, [:args], [:lasgn, :a, [:zarray]], [:return, [:lvar, :a]]]]],
      "Rewriter"    => s(:defn,
                         :empty,
                         s(:args),
                         s(:scope, s(:block, s(:lasgn, :a, s(:array)), s(:return, s(:lvar, :a))))),
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
      "Ruby"        => "def |()\n  nil\nend",
      "ParseTree"   => [:defn, :|, [:scope, [:block, [:args], [:nil]]]],
      "Rewriter"    => s(:defn, :|,
                         s(:args), s(:scope, s(:block, s(:nil)))),
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
      "Ruby"        => "def something?()\n  nil\nend",
      "ParseTree"   => [:defn, :something?, [:scope, [:block, [:args], [:nil]]]],
      "Rewriter"    => s(:defn, :something?,
                         s(:args), s(:scope, s(:block, s(:nil)))),
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
      "Ruby"        => "def aliased()\n  puts(42)\nend",
      "ParseTree" => [:defn, :aliased,
                       [:fbody,
                       [:scope,
                         [:block,
                           [:args],
                           [:fcall, :puts, [:array, [:lit, 42]]]]]]],
      "Rewriter"    => s(:defn, :aliased,
                         s(:args),
                         s(:scope,
                           s(:block,
                             s(:call, nil, :puts, s(:arglist, s(:lit, 42)))))),
      "TypeChecker" => :skip,
      "CRewriter" => :skip,
      "RubyToRubyC" => :skip,
      "RubyToAnsiC" => :skip,
    },

    "defn_optargs" => {
      "Ruby"        => "def x(a, *args)\n  p(a, args)\nend",
      "ParseTree" => [:defn, :x,
                      [:scope,
                       [:block,
                        [:args, :a, :"*args"],
                        [:fcall, :p,
                         [:array, [:lvar, :a], [:lvar, :args]]]]]],
      "Rewriter"    => s(:defn, :x,
                         s(:args, :a, :"*args"),
                         s(:scope,
                           s(:block,
                             s(:call, nil, :p,
                               s(:arglist, s(:lvar, :a), s(:lvar, :args)))))),
      "TypeChecker" => :skip,
      "CRewriter" => :skip,
      "RubyToRubyC" => :skip,
      "RubyToAnsiC" => :skip,
    },

    "dmethod_added" => {
      "Ruby"        => "def dmethod_added\n  define_method(:bmethod_added)\n  x {|(x + 1)|\n  }end",
      "ParseTree"   => [:defn,
        :dmethod_added,
        [:dmethod,
          :bmethod_maker,
          [:scope,
            [:block,
              [:args],
              [:iter,
                [:fcall, :define_method, [:array, [:lit, :bmethod_added]]],
                [:dasgn_curr, :x],
                [:call, [:dvar, :x], :+, [:array, [:lit, 1]]]]]]]],
      "Rewriter" => s(:defn,
                      :dmethod_added,
                      s(:args, :x),
                      s(:scope,
                        s(:block,
                          s(:call, s(:lvar, :x), :+,
                            s(:arglist, s(:lit, 1)))))),
      "TypeChecker" => :skip,
      "CRewriter" => :skip,
      "RubyToRubyC" => :skip,
      "RubyToAnsiC" => :skip,
    },

    "global" => {
      "Ruby"        => "$stderr",
      "ParseTree"   =>  [:gvar, :$stderr],
      "Rewriter"    => s(:gvar, :$stderr),
      # TODO: test s(:gvar, :$stderr) != t(:gvar, $stderr, Type.file)
      "TypeChecker" => t(:gvar, :$stderr, Type.file),
      "CRewriter" => :same,
      "RubyToRubyC" => "rb_gv_get(\"$stderr\")",
      "RubyToAnsiC" => "stderr",
    },

    "interpolated" => {
      "Ruby"        => "\"var is \#{argl}. So there.\"",
      "ParseTree"   => [:dstr,
        "var is ", [:lvar, :argl], [:str, ". So there."]],
      "Rewriter" => s(:dstr,
                      "var is ", s(:lvar, :argl), s(:str, ". So there.")),
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
      "Ruby"        => "loop do end",
      "ParseTree"   => [:iter, [:fcall, :loop], nil],
      "Rewriter"    => s(:iter,
                         s(:call, nil, :loop, nil),
                         s(:dasgn_curr, :temp_1),
                         nil),
      "TypeChecker" => t(:iter,
                         t(:call, nil, :loop, nil, Type.unknown),
                         t(:dasgn_curr, :temp_1, Type.unknown),
                         nil,
                         Type.unknown),
      "CRewriter" => [:defx,
                      t(:iter,
                       t(:call, nil, :loop, nil, Type.unknown),
                       t(:args,
                         t(:array, t(:dasgn_curr, :temp_1, Type.unknown), Type.void),
                         t(:array, Type.void), Type.void),
                        t(:call, nil,
                          :temp_2,
                          s(:arglist, s(:dasgn_curr, :temp_1, Type.unknown),
                            t(:nil)))),
                      [t(:defx,
                         :temp_2,
                         t(:args, :temp_2, :temp_3),
                         t(:scope, t(:block, nil)), Type.void)]],
      "RubyToRubyC" => "",
      "RubyToAnsiC" => "",
    },

    "iteration2" => {
      "ParseTree"   => [:iter,
        [:call, [:lvar, :arrays], :each],
        [:dasgn_curr, :x],
        [:fcall, :puts, [:arrays, [:dvar, :x]]]],
      "Rewriter" => s(:iter,
                      s(:call, s(:lvar, :arrays), :each, nil),
                      s(:dasgn_curr, :x),
                      s(:call, nil, :puts, s(:arglist, s(:dvar, :x)))),
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
                           t(:array, t(:dasgn_curr, :x, Type.str), Type.void),
                           t(:array, t(:lvar, :arrays, Type.value), Type.void), Type.void),
                         t(:call, nil, :temp_1, t(:arglist, t(:dasgn_curr, :x, Type.str), t(:nil)))),
                       [t(:defx,
                          :temp_1,
                          t(:args, :temp_2, :temp_3),
                          t(:scope,
                            t(:block,
                              t(:call,
                                nil,
                                :puts,
                                t(:arglist, t(:dvar, :x, Type.str)), Type.void))), Type.void)]],
      "RubyToRubyC" => 'unsigned long index_temp_1;
VALUE temp_2 = rb_funcall(arrays, rb_intern("to_a"), 0);
unsigned long temp_1_max = FIX2LONG(rb_funcall(temp_2, rb_intern("size"), 0));
for (index_temp_1 = 0; index_temp_1 < temp_1_max; ++index_temp_1) {
VALUE x;
x = rb_funcall(temp_2, rb_intern("at"), 1, LONG2FIX(index_temp_1));
rb_funcall(self, rb_intern("puts"), 1, x);
}",
      "RubyToAnsiC" => "unsigned long index_x;
for (index_x = 0; arrays[index_x] != NULL; ++index_x) {
str x = arrays[index_x];
puts(x);
}',
    },


    "iteration4" => {
      "Ruby"        => "1.upto(3) {|n|\n  puts(n.to_s)\n}",
      "ParseTree"   => [:iter,
        [:call, [:lit, 1], :upto, [:array, [:lit, 3]]],
        [:dasgn_curr, :n],
        [:fcall, :puts, [:array, [:call, [:dvar, :n], :to_s]]]],
      "Rewriter" => s(:dummy,
                      s(:lasgn, :n, s(:lit, 1)),
                      s(:while,
                        s(:call, s(:lvar, :n), :<=, s(:arglist, s(:lit, 3))),
                        s(:block,
                          s(:call,
                            nil,
                            :puts,
                            s(:arglist, s(:call, s(:lvar, :n), :to_s, nil))),
                          s(:lasgn, :n,
                            s(:call, s(:lvar, :n),
                              :+,
                              s(:arglist, s(:lit, 1))))), true)),
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
      "RubyToRubyC" => '',
      "RubyToAnsiC" => 'n = 1;
while (n <= 3) {
puts(to_s(n));
n = n + 1;
}',
    },

    "iteration5" => {
      "Ruby"        => "3.downto(1) {|n|\n  puts(n.to_s)\n}",
      "ParseTree"   => [:iter,
        [:call, [:lit, 3], :downto, [:array, [:lit, 1]]],
        [:dasgn_curr, :n],
        [:fcall, :puts, [:array, [:call, [:dvar, :n], :to_s]]]],
      "Rewriter" => s(:dummy, s(:lasgn, :n, s(:lit, 3)), s(:while,
                      s(:call, s(:lvar, :n), :>=, s(:arglist, s(:lit, 1))),
                      s(:block,
                        s(:call, nil, :puts,
                          s(:arglist, s(:call, s(:lvar, :n), :to_s, nil))),
                        s(:lasgn, :n, s(:call, s(:lvar, :n),
                                        :-, s(:arglist, s(:lit, 1))))), true)),
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
      "RubyToRubyC" => '',
      "RubyToAnsiC" => 'n = 3;
while (n >= 1) {
puts(to_s(n));
n = n - 1;
}',
    },

    "iteration6" => {
      "Ruby"        => "while ((argl >= (1))) do\nputs((\"hello\"))\nargl = (argl - (1))\n\nend",
      "ParseTree"   => [:while, [:call, [:lvar, :argl],
                        :>=, [:arglist, [:lit, 1]]], [:block,
                        [:call, nil, :puts, [:arglist, [:str, "hello"]]],
                        [:lasgn,
                          :argl,
                          [:call, [:lvar, :argl],
                            :-, [:arglist, [:lit, 1]]]]], true],
      "Rewriter" => s(:while,
                      s(:call, s(:lvar, :argl),
                        :>=, s(:arglist, s(:lit, 1))),
                      s(:block,
                        s(:call, nil, :puts, s(:arglist, s(:str, "hello"))),
                        s(:lasgn,
                          :argl,
                          s(:call, s(:lvar, :argl),
                            :-, s(:arglist, s(:lit, 1))))), true),
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
      "RubyToRubyC" => '',
      "RubyToAnsiC" => 'while (argl >= 1) {
puts("hello");
argl = argl - 1;
}',
    },

    # TODO: this might still be too much
    "lasgn_call" => {
      "Ruby"        => "c = 2 + 3",
      "ParseTree"   => [:lasgn, :c, [:call, [:lit, 2], :+, [:arglist, [:lit, 3]]]],
      "Rewriter"    => s(:lasgn, :c, s(:call, s(:lit, 2), :+, s(:arglist, s(:lit, 3)))),
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
      "Ruby"        => "var = [\"foo\", \"bar\"]",
      "ParseTree"   => [:lasgn, :var, [:array,
                                         [:str, "foo"],
                                         [:str, "bar"]]],
      "Rewriter"    => s(:lasgn, :var, s(:array,
                                         s(:str, "foo"),
                                         s(:str, "bar"))),
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
      "Ruby"        => "false",
      "ParseTree"   => [:false],
      "Rewriter"    => s(:false),
      "TypeChecker" => t(:false, Type.bool),
      "CRewriter" => :same,
      "RubyToRubyC" => "Qfalse",
      "RubyToAnsiC" => "0",
    },

    "lit_bool_true" => {
      "Ruby"        => "true",
      "ParseTree"   => [:true],
      "Rewriter"    => s(:true),
      "TypeChecker" => t(:true, Type.bool),
      "CRewriter" => :same,
      "RubyToRubyC" => "Qtrue",
      "RubyToAnsiC" => "1",
    },

    "lit_float" => {
      "Ruby"        => "1.1",
      "ParseTree"   => [:lit, 1.1],
      "Rewriter"    => s(:lit, 1.1),
      "TypeChecker" => t(:lit, 1.1, Type.float),
      "CRewriter" => :same,
      "RubyToRubyC" => "rb_float_new(1.1)",
      "RubyToAnsiC" => "1.1",
    },

    "lit_long" => {
      "Ruby"        => "1",
      "ParseTree"   => [:lit, 1],
      "Rewriter"    => s(:lit, 1),
      "TypeChecker" => t(:lit, 1, Type.long),
      "CRewriter" => :same,
      "RubyToRubyC" => "LONG2NUM(1)",
      "RubyToAnsiC" => "1",
    },

    "lit_sym" => {
      "Ruby"        => ":x",
      "ParseTree"   => [:lit, :x],
      "Rewriter"    => s(:lit, :x),
      "TypeChecker" => t(:lit, :x, Type.symbol),
      "CRewriter" => :same,
      "RubyToRubyC" => 'ID2SYM(rb_intern("x"))',
      "RubyToAnsiC" => '"x"', # HACK WRONG! (or... is it?)
    },

    "lit_str" => {
      "Ruby"        => "\"x\"",
      "ParseTree"   => [:str, "x"],
      "Rewriter"    => s(:str, "x"),
      "TypeChecker" => t(:str, "x", Type.str),
      "CRewriter" => :same,
      "RubyToRubyC" => 'rb_str_new2("x")',
      "RubyToAnsiC" => '"x"',
    },

    "multi_args" => {
      "Ruby"        => "def multi_args(arg1, arg2)\n  arg3 = ((arg1 * arg2) * 7)\n  puts(arg3.to_s)\n  return \"foo\"\nend",
      "ParseTree"   => [:defn, :multi_args,
        [:scope,
          [:block,
            [:args, :arg1, :arg2],
            [:lasgn,
              :arg3,
              [:call,
                [:call, [:lvar, :arg1], :*, [:array, [:lvar, :arg2]]],
                :*,
                [:array, [:lit, 7]]]],
            [:fcall, :puts, [:array, [:call, [:lvar, :arg3], :to_s]]],
            [:return, [:str, "foo"]]]]],
      "Rewriter" => s(:defn, :multi_args,
                      s(:args, :arg1, :arg2),
                      s(:scope,
                        s(:block,
                          s(:lasgn, :arg3,
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
                            s(:arglist,
                              s(:call,
                                s(:lvar, :arg3),
                                :to_s,
                                nil))),
                          s(:return, s(:str, "foo"))))),
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
      "Ruby"        => "method",
      "ParseTree"   => [:vcall, :method],
      "Rewriter"    => s(:call, nil, :method, nil),
      "TypeChecker" => t(:call, nil, :method, nil, Type.unknown),
      "CRewriter" => :same,
      "RubyToRubyC" => "rb_funcall(self, rb_intern(\"method\"), 0)",
      "RubyToAnsiC" => "method()",
    },

    "whiles" => {
      "Ruby"        => "def whiles()\n  while (false) do\n    puts(\"false\")\n  end\n  begin\n    puts(\"true\")\n  end while (false)\nend",
      "ParseTree"   => [:defn,
        :whiles,
        [:scope,
          [:block,
            [:args],
            [:while, [:false],
              [:fcall, :puts, [:array, [:str, "false"]]], true],
            [:while, [:false],
              [:fcall, :puts, [:array, [:str, "true"]]], false]]]],
      "Rewriter" => s(:defn,
               :whiles,
               s(:args),
               s(:scope,
                 s(:block,
                   s(:while,
                     s(:false),
                     s(:call, nil, :puts, s(:arglist, s(:str, "false"))),
                     true),
                   s(:while,
                     s(:false),
                     s(:call, nil, :puts, s(:arglist, s(:str, "true"))),
                     false)))),
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
      "Ruby"        => "a = []",
      "ParseTree"   => [:lasgn, :a, [:zarray]],
      "Rewriter" => s(:lasgn, :a, s(:array)),
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
          extra_input.each do |input| processor.process(input) end
          extra = processor.extra_methods rescue []
          assert_equal extra_expected, extra
        end
      end
    end
  end

  def test_stoopid
    # do nothing - shuts up empty test class requirement
  end

end
