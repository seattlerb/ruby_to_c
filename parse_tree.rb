#!/usr/local/bin/ruby -w

require "inline"

class ParseTree

  inline do |builder|
    builder.add_type_converter("VALUE", '', '')
    builder.add_type_converter("NODE *", '(NODE *)', '(VALUE)')
    builder.include '"intern.h"'
    builder.include '"node.h"'

    builder.c_raw %q{
      static VALUE node_to_sym(NODE * n) {
        char node_type_string[][60] = {
	  //  00
	  "method", "fbody", "cfunc", "scope", "block",
	  "if", "case", "when", "opt_n", "while",
	  //  10
	  "until", "iter", "for", "break", "next",
	  "redo", "retry", "begin", "rescue", "resbody",
	  //  20
	  "ensure", "and", "or", "not", "masgn",
	  "lasgn", "dasgn", "dasgn_curr", "gasgn", "iasgn",
	  //  30
	  "cdecl", "cvasgn", "cvdecl", "op_asgn1", "op_asgn2",
	  "op_asgn_and", "op_asgn_or", "call", "fcall", "vcall",
	  //  40
	  "super", "zsuper", "array", "zarray", "hash",
	  "return", "yield", "lvar", "dvar", "gvar",
	  //  50
	  "ivar", "const", "cvar", "nth_ref", "back_ref",
	  "match", "match2", "match3", "lit", "str",
	  //  60
	  "dstr", "xstr", "dxstr", "evstr", "dregx",
	  "dregx_once", "args", "argscat", "argspush", "splat",
	  //  70
	  "to_ary", "svalue", "block_arg", "block_pass", "defn",
	  "defs", "alias", "valias", "undef", "class",
	  //  80
	  "module", "sclass", "colon2", "colon3", "cref",
	  "dot2", "dot3", "flip2", "flip3", "attrset",
	  //  90
	  "self", "nil", "true", "false", "defined",
	  //  95
	  "newline", "postexe",
#ifdef C_ALLOCA
	  "alloca",
#endif
	  "dmethod", "bmethod",
	  // 100 / 99
	  "memo", "ifunc", "dsym", "attrasgn",
	  // 104 / 103
	  "last" 
        };

	if (n) {
	  return ID2SYM(rb_intern(node_type_string[nd_type(n)]));
        } else {
	  return ID2SYM(rb_intern("ICKY"));
	}
      }
  }

    builder.c_raw %q^
// FIX!!!
static ID *dump_local_tbl;

static void add_to_parse_tree(VALUE ary, NODE * n) {
  NODE * volatile node = n;
  NODE * volatile contnode = NULL;
  VALUE old_ary;
  VALUE current;


    if (!node) return;

again:

    current = rb_ary_new();
    rb_ary_push(ary, current);
    rb_ary_push(current, node_to_sym(node));

again_no_block:


    switch (nd_type(node)) {

    case NODE_BLOCK:
      if (contnode) {
        add_to_parse_tree(current, node);
        break;
      }

      contnode = node->nd_next;

      // NOTE: this will break the moment there is a block w/in a block
      old_ary = ary;
      ary = current;
      node = node->nd_head;
      goto again;
      break;

    case NODE_FBODY:
    case NODE_DEFINED:
      add_to_parse_tree(current, node->nd_head);
      break;

    case NODE_COLON2:
      add_to_parse_tree(current, node->nd_head);
      rb_ary_push(current, rb_str_new2(rb_id2name(node->nd_mid)));
      break;

    case NODE_BEGIN:
      node = node->nd_body;
      goto again;

    case NODE_MATCH2:
    case NODE_MATCH3:
      add_to_parse_tree(current, node->nd_recv);
      add_to_parse_tree(current, node->nd_value);
      break;

    case NODE_OPT_N:
      add_to_parse_tree(current, node->nd_body);
      break;

    case NODE_IF:
      add_to_parse_tree(current, node->nd_cond);
      add_to_parse_tree(current, node->nd_body);
      add_to_parse_tree(current, node->nd_else);
      break;

  case NODE_WHEN:
  case NODE_CASE:
    {
      NODE *tag;
      if (nd_type(node) == NODE_CASE) {
	add_to_parse_tree(current, node->nd_head);
	node = node->nd_body;
      }
      while (node) {
	if (nd_type(node) != NODE_WHEN) {
	  add_to_parse_tree(current, node);
	  break;
	}
	tag = node->nd_head;
	while (tag) {
	  if (nd_type(tag->nd_head) == NODE_WHEN) {
	    add_to_parse_tree(current, tag->nd_head->nd_head);
	  } else {
	    add_to_parse_tree(current, tag->nd_head);
	  }
	  tag = tag->nd_next;
	}
	add_to_parse_tree(current, node->nd_body);
	node = node->nd_next;
      }
    }
    break;

  case NODE_WHILE:
  case NODE_UNTIL:
    add_to_parse_tree(current,  node->nd_cond);
    add_to_parse_tree(current,  node->nd_body); 
    break;

  case NODE_BLOCK_PASS:
    add_to_parse_tree(current, node->nd_body);
    add_to_parse_tree(current, node->nd_iter);
    break;

  case NODE_ITER:
  case NODE_FOR:
    add_to_parse_tree(current, node->nd_iter);
    if (node->nd_var != (NODE *)1)
      add_to_parse_tree(current, node->nd_var);
    add_to_parse_tree(current, node->nd_body);
    break;

  case NODE_BREAK:
  case NODE_NEXT:
  case NODE_YIELD:
    if (node->nd_stts)
      add_to_parse_tree(current, node->nd_stts);
    break;

  case NODE_RESCUE:
    {
      NODE *resq, *n;
      int i;

      add_to_parse_tree(current, node->nd_head);
      resq = node->nd_resq;
      while (resq) {
	if (nd_type(resq) == NODE_ARRAY) {
	  n = resq;
	  for (i = 0; i < resq->nd_alen; i++) {
	    add_to_parse_tree(current, n->nd_head);
	    n = n->nd_next;
	  }
	} else {
	  add_to_parse_tree(current, resq->nd_args);
	}
	add_to_parse_tree(current, resq->nd_body);
	resq = resq->nd_head;
      }
      if (node->nd_else) {
	add_to_parse_tree(current, node->nd_else);
      }
    }
    break;
	
  case NODE_ENSURE:
    add_to_parse_tree(current, node->nd_head);
    if (node->nd_ensr) {
      add_to_parse_tree(current, node->nd_ensr);
    }
    break;

  case NODE_AND:
  case NODE_OR:
    add_to_parse_tree(current, node->nd_1st);
    add_to_parse_tree(current, node->nd_2nd);
    break;

  case NODE_NOT:
    add_to_parse_tree(current, node->nd_body);
    break;

  case NODE_DOT2:
  case NODE_DOT3:
  case NODE_FLIP2:
  case NODE_FLIP3:
    add_to_parse_tree(current, node->nd_beg);
    add_to_parse_tree(current, node->nd_end);
    break;

  case NODE_RETURN:
    if (node->nd_stts)
      add_to_parse_tree(current, node->nd_stts);
    break;

  case NODE_ARGSCAT:
  case NODE_ARGSPUSH:
    add_to_parse_tree(current, node->nd_head);
    add_to_parse_tree(current, node->nd_body);
    break;

  case NODE_CALL:
  case NODE_FCALL:
  case NODE_VCALL:
    if (nd_type(node) != NODE_FCALL)
      add_to_parse_tree(current, node->nd_recv);
    rb_ary_push(current, rb_str_new2(rb_id2name(node->nd_mid)));
    if (node->nd_args || nd_type(node) != NODE_FCALL)
      add_to_parse_tree(current, node->nd_args);
    break;

  case NODE_SUPER:
    add_to_parse_tree(current, node->nd_args);
    break;

  case NODE_DMETHOD:
    {
      struct METHOD *data;
      Data_Get_Struct(node->nd_cval, struct METHOD, data);
      break;
    }

  case NODE_SCOPE:
    dump_local_tbl = node->nd_tbl;
    add_to_parse_tree(current, node->nd_next);
    break;

  case NODE_OP_ASGN1:
    add_to_parse_tree(current, node->nd_recv);
    add_to_parse_tree(current, node->nd_args->nd_next);
    add_to_parse_tree(current, node->nd_args->nd_head);
    break;

  case NODE_OP_ASGN2:
    add_to_parse_tree(current, node->nd_recv);
    add_to_parse_tree(current, node->nd_value);
    break;

  case NODE_OP_ASGN_AND:
  case NODE_OP_ASGN_OR:
    add_to_parse_tree(current, node->nd_head);
    add_to_parse_tree(current, node->nd_value);
    break;

  case NODE_MASGN:
    add_to_parse_tree(current, node->nd_head);
    if (node->nd_args) {
      if (node->nd_args != (NODE *)-1) {
	add_to_parse_tree(current, node->nd_args);
      }
    }
    add_to_parse_tree(current, node->nd_value);
    break;

  case NODE_LASGN:
  case NODE_IASGN:
  case NODE_DASGN:
  case NODE_DASGN_CURR:
  case NODE_CDECL:
  case NODE_CVASGN:
  case NODE_CVDECL:
  case NODE_GASGN:
    rb_ary_push(current, rb_str_new2(rb_id2name(node->nd_vid)));
    add_to_parse_tree(current, node->nd_value);
    break;

  case NODE_HASH:
    {
      NODE *list;
	
      list = node->nd_head;
      while (list) {
	add_to_parse_tree(current, list->nd_head);
	list = list->nd_next;
	if (list == 0)
	  rb_bug("odd number list for Hash");
	add_to_parse_tree(current, list->nd_head);
	list = list->nd_next;
      }
    }
    break;

  case NODE_ARRAY:
      while (node) {
	add_to_parse_tree(current, node->nd_head);
        node = node->nd_next;
      }
    break;

  case NODE_DSTR:
  case NODE_DXSTR:
  case NODE_DREGX:
  case NODE_DREGX_ONCE:
    {
      VALUE str, str2;
      NODE *list = node->nd_next;
      if (nd_type(node) == NODE_DREGX || nd_type(node) == NODE_DREGX_ONCE) {
	int flag;
	flag = node->nd_cflag & 0xf;
	break;
      }
      while (list) {
	if (list->nd_head) {
	  switch (nd_type(list->nd_head)) {
	  case NODE_STR:
	    break;
	  case NODE_EVSTR:
	    add_to_parse_tree(current, list->nd_head->nd_body);
	    break;
	  default:
	    add_to_parse_tree(current, list->nd_head);
	    break;
	  }
	}
	list = list->nd_next;
      }
    }
    break;

  case NODE_DEFN:
  case NODE_DEFS:
    if (node->nd_defn) {
      if (nd_type(node) == NODE_DEFS)
	add_to_parse_tree(current, node->nd_recv);
      rb_ary_push(current, rb_str_new2(rb_id2name(node->nd_mid)));
      add_to_parse_tree(current, node->nd_defn);
    }
    break;

  case NODE_CLASS:
  case NODE_MODULE:
    rb_ary_push(current, rb_str_new2(rb_id2name((long)node->nd_cpath->nd_mid)));
    if (node->nd_super && nd_type(node) == NODE_CLASS) {
      add_to_parse_tree(current, node->nd_super);
    }
    add_to_parse_tree(current, node->nd_body);
    break;

  case NODE_SCLASS:
    add_to_parse_tree(current, node->nd_recv);
    add_to_parse_tree(current, node->nd_body);
    break;

  case NODE_ARGS:
    if (dump_local_tbl && 
	(node->nd_cnt || node->nd_opt || node->nd_rest != -1)) {
      int i;
      NODE *optnode;

      for (i = 0; i < node->nd_cnt; i++) {
        // regular arg names
        rb_ary_push(current, rb_str_new2(rb_id2name(dump_local_tbl[i + 3])));
      }

      optnode = node->nd_opt;
      while (optnode) {
        // optional arg names
        rb_ary_push(current, rb_str_new2(rb_id2name(dump_local_tbl[i + 3])));
	i++;
	optnode = optnode->nd_next;
      }
      if (node->nd_rest != -1) {
        // *arg name
        rb_ary_push(current, rb_str_new2(rb_id2name(dump_local_tbl[node->nd_rest + 1])));
      }
      optnode = node->nd_opt;
      // 
      if (optnode) {
	add_to_parse_tree(current, node->nd_opt);
      }
    }
    break;
	
    case NODE_LVAR:
    case NODE_DVAR:
    case NODE_IVAR:
    case NODE_CVAR:
    case NODE_CONST:
    case NODE_ATTRSET:
      rb_ary_push(current, rb_str_new2(rb_id2name(node->nd_vid)));
      break;

    case NODE_STR:
    case NODE_LIT:
      rb_ary_push(current, node->nd_lit);
      break;

    case NODE_NEWLINE:
      rb_ary_push(current, INT2FIX(nd_line(node)));
      rb_ary_push(current, rb_str_new2(node->nd_file));
      rb_ary_pop(ary); // nuke it for now

      node = node->nd_next;
      goto again;

    // these are things we know we do not need to translate to C.
    case NODE_BLOCK_ARG:
    case NODE_SELF:
    case NODE_NIL:
    case NODE_TRUE:
    case NODE_FALSE:
    case NODE_GVAR:
    case NODE_ZSUPER:
    case NODE_BMETHOD:
    case NODE_REDO:
    case NODE_RETRY:
    case NODE_COLON3:
    case NODE_NTH_REF:
    case NODE_BACK_REF:
    case NODE_ZARRAY:
    case NODE_XSTR:
    case NODE_UNDEF:
    case NODE_ALIAS:
    case NODE_VALIAS:
    break;

    default:
      rb_ary_push(current, INT2FIX(-99));
      rb_ary_push(current, INT2FIX(nd_type(node)));
      break;
    }

  finish:
    if (contnode) {
	node = contnode;
	contnode = NULL;
        current = ary;
        ary = old_ary;
        old_ary = Qnil;
	goto again_no_block;
    }
  }
^

    builder.c %q{
static VALUE parse_tree_for_method(VALUE klass, VALUE method) {
  NODE *node = NULL;
  ID id;
  VALUE result = rb_ary_new();

  id = rb_to_id(method);
  if (st_lookup(RCLASS(klass)->m_tbl, id, &node)) {
    rb_ary_push(result, ID2SYM(rb_intern("defn")));
    rb_ary_push(result, method);
    add_to_parse_tree(result, node->nd_body);
  } else {
    rb_ary_push(result, Qnil);
  }

  return result;
}
}
  end

  def parse_tree(klass, meth=nil)
    code = []
    if meth then
      code = parse_tree_for_method(klass, meth.to_s)
    else
      klass.instance_methods(false).sort.each do |m|
	code << parse_tree_for_method(klass, m)
      end
    end
    return code
  end

end
