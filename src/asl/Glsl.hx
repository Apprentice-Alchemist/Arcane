package asl;

import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;

// enum GType {
// 	GTVec(size:Int, t:GType);
// }

// enum GStatement {
// 	GSVarDecl(name:String, t:GType, ?expr:GExpr);
// 	GSExpr(e:GExpr);
// }

// enum GExpr {
// 	GECall();
// 	GEBinop();
// 	GEUnop();
// 	GESwizzle();
// }

class Glsl {}

class Context {
	var statementBuf:StringBuf;
	var exprBuf:Null<StringBuf>;

	public function new() {
		statementBuf = new StringBuf();
	}

	function error(e:String, p:Position):Dynamic {
		#if macro
		return haxe.macro.Context.error(e, p);
		#else
		throw e;
		#end
	}

	function unsupported(e:haxe.macro.Type.TypedExpr):Dynamic {
		return error("Unsupported expression", e.pos);
	}

	function expr(e:String) {
		if (exprBuf == null)
			exprBuf = new StringBuf();
		exprBuf.add(e);
	}

	function stmnt(e:String) {
		statementBuf.add(e);
		statementBuf.addChar(";".code);
	}

	function flushExpr():String {
		return exprBuf?.toString() ?? "";
	}

	function convType(e:Type) {
		switch e {
			case TMono(t):
			case TEnum(t, params):
			case TInst(t, params):
			case TType(t, params):
			case TFun(args, ret):
			case TAnonymous(a):
			case TDynamic(t):
			case TLazy(f):
			case TAbstract(t, params):
				var t = t.get();
				if (t.meta.has(":builtin")) {
					var meta = t.meta.extract(":builtin")[0];
					var builtin = switch meta.params[0].expr {
						case EConst(CIdent(i)): i;
						case _: throw "assert";
					}

					switch builtin {
						case "vec2":
						case "vec3":
						case "vec4":
					}
				}
		}
	}

	function convExpr(expression:TypedExpr) {
		switch expression.expr {
			case TConst(c):
				switch c {
					case TInt(i): this.expr(Std.string(i));
					case TFloat(s): this.expr(s);
					case TBool(b): this.expr(b ? "true" : "false");
					case TString(_), TNull, TThis, TSuper: unsupported(expression);
				}
			case TLocal(v):
			case TArray(e1, e2):
			case TBinop(op, e1, e2):
				switch op {
					case OpAdd:
					case OpMult:
					case OpDiv:
					case OpSub:
					case OpAssign:
					case OpEq:
					case OpNotEq:
					case OpGt:
					case OpGte:
					case OpLt:
					case OpLte:
					case OpAnd:
					case OpOr:
					case OpXor:
					case OpBoolAnd:
					case OpBoolOr:
					case OpShl:
					case OpShr:
					case OpUShr:
					case OpMod:
					case OpAssignOp(op):
					case _: unsupported(expression);
				}
			case TField(e, fa):
			case TTypeExpr(m):
				switch m {
					case TClassDecl(c):
					case TEnumDecl(e):
					case TTypeDecl(t):
					case TAbstract(a):
				}
			case TParenthesis(e):
			case TObjectDecl(fields):
			case TArrayDecl(el):
			// case TCall(_.expr => TField(_.expr => TTypeExpr(TClassDecl(_.get() => _.name => "Builtins")), FStatic(c, _.get() => cf)), args):

			case TCall(e, el):
			case TNew(_, _, _):
				unsupported(expression);
			case TUnop(op, postFix, e):
				if (!postFix) {
					convExpr(e);
				}
				switch op {
					case OpIncrement: expr('++');
					case OpDecrement: expr('--');
					case OpNot: unsupported(expression);
					case OpNeg: unsupported(expression);
					case OpNegBits: unsupported(expression);
					case OpSpread: unsupported(expression);
				}
				if (postFix) {
					convExpr(e);
				}
			case TFunction(tfunc):
				unsupported(expression);
			case TVar(v, e):
				convType(v.t);
				expr(' ${v.name}');
				if (expr != null) {
					expr(' = ');
					convExpr(e);
				}
			case TBlock(el):
				var last = el.pop();
				for (e in el) {
					convExpr(e);
					stmnt(flushExpr());
				}
				if (last != null) {
					if (!last.t.match(TAbstract(_.get() => _.name => "Void", []))) {
						convType(last.t);
						expr(' __blockvalue__ = ');
						convExpr(last);
						stmnt(flushExpr());
					}
				}
			case TFor(v, e1, e2):
			case TIf(econd, eif, eelse):
			case TWhile(econd, e, normalWhile):
			case TSwitch(e, cases, edef):
			case TTry(e, catches):
				error("Exceptions are not supported in shaders", e.pos);
			case TReturn(e):
			case TBreak:
				expr("break");
			case TContinue:
				expr("continue");
			case TThrow(e):
				error("Exceptions are not supported in shaders", e.pos);
			case TCast(e, m):
				unsupported(expression);
			case TMeta({name: ":swizzle", params: [macro $i{swizzle}], pos: _}, _):
			case TMeta(_, e1):
				convExpr(e1);
			case TEnumParameter(e1, ef, index):
				unsupported(expression);
			case TEnumIndex(_):
				unsupported(expression);
			case TIdent(i):
				error('Unknown identifier: $i', expression.pos);
		}
	}
}
