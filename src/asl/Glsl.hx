package asl;

using haxe.macro.Tools;

import haxe.macro.Type;

class Glsl {
	static function convType(e:Type) {
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
				if(t.meta.has(":builtin")) {
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

	static function convExpr(e:TypedExpr) {
		switch e.expr {
			case TConst(c):
			case TLocal(v):
			case TArray(e1, e2):
			case TBinop(op, e1, e2):
			case TField(e, fa):
			case TTypeExpr(m):
			case TParenthesis(e):
			case TObjectDecl(fields):
			case TArrayDecl(el):
			case TCall(e, el):
			case TNew(c, params, el):
			case TUnop(op, postFix, e):
			case TFunction(tfunc):
			case TVar(v, expr):
			case TBlock(el):
			case TFor(v, e1, e2):
			case TIf(econd, eif, eelse):
			case TWhile(econd, e, normalWhile):
			case TSwitch(e, cases, edef):
			case TTry(e, catches):
			case TReturn(e):
			case TBreak:
			case TContinue:
			case TThrow(e):
			case TCast(e, m):
			case TMeta(m, e1):
			case TEnumParameter(e1, ef, index):
			case TEnumIndex(e1):
			case TIdent(s):
		}
	}
}