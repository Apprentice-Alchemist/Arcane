package asl;

import asl.Ast;
import haxe.macro.Expr;

class Typer {
	public function typeModule():ShaderModule {
		final m:ShaderModule = {
			uniforms: [],
			stage: cast null,
			outputs: [],
			inputs: [],
			functions: [],
			entryPoint: "main"
		};

		return m;
	}

	static function tryUnify(a:Type, b:Type):Bool {
		if (a == b)
			return true;
		return switch [a, b] {
			case [TVec2(a), TVec2(b)] if (a == b): true;
			case [TVec3(a), TVec3(b)] if (a == b): true;
			case [TVec4(a), TVec4(b)] if (a == b): true;

			case [TMat2(a), TMat2(b)] if (a == b): true;
			case [TMat3(a), TMat3(b)] if (a == b): true;
			case [TMat4(a), TMat4(b)] if (a == b): true;
			case [TArray(t1, size1), TArray(t2, size2)] if (t1 == t2 && size1 == size2): true;
			case [_, _]: false;
		}
	}

	static function unify(a, b) {
		if (tryUnify(a, b))
			return a
		else
			throw "could not unify " + a + " and " + b;
	}

	static function error(message:String, pos:Position):Dynamic {
		#if macro
		return haxe.macro.Context.error(message, pos);
		#else
		return throw message;
		#end
	}

	inline static function t(e:TypedExprDef, type:Type, p):TypedExpr {
		return {
			expr: e,
			pos: p,
			t: type
		}
	}

	static function typeExpr(e:Expr):TypedExpr {
		return switch e.expr {
			case EConst(CIdent(ident)): cast null;
			case EConst(c):
				return switch c {
					case CInt(i):
						t(TConst(TInt(Std.parseInt(i))), TInt, e.pos);
					case CFloat(f):
						t(TConst(TFloat(f)), TFloat, e.pos);
					case _: error("Invalid expression", e.pos);
				}
			case EArray(typeExpr(_) => e1, typeExpr(_) => e2):
				var _t = switch e1.t {
					case TVec2(t), TVec3(t), TVec4(t), TMat2(t), TMat3(t), TMat4(t), TArray(t, _): t;
					case _: error("Cannot do array access on " + e1.t,e1.pos);
				}
				if(e2.t != TInt) error("Expected an int",e1.pos);
				t(TypedExprDef.TArray(e1,e1),_t,e.pos);
			// case EBinop(op, e1, e2):
			// case EField(e, field):
			// case EParenthesis(e):
			// case EObjectDecl(fields):
			// case EArrayDecl(values):
			// case ECall(e, params):
			// case EUnop(op, postFix, e):
			// case EVars(vars):
			// case EBlock(exprs):
			// case EFor(it, expr):
			// case EIf(econd, eif, eelse):
			// case EWhile(econd, e, normalWhile):
			// case ESwitch(e, cases, edef):

			// case EReturn(e):
			// case EBreak:
			// case EContinue:
			// case EDisplay(e, displayKind):
			// case ETernary(econd, eif, eelse):
			// case EMeta(s, e):
			default: cast null;
		}
	}

	// static function typeof(e:Expr):Type {
	// 	return switch e.expr {
	// 		case EConst(c): switch c {
	// 				case CInt(v): TInt;
	// 				case CFloat(f): TFloat;
	// 				case CString(s, kind): throw "no strings";
	// 				case CIdent(s): throw "ident";
	// 				case CRegexp(r, opt): throw "no regexes";
	// 			}
	// 		case EArray(e1, e2):
	// 		case EBinop(op, e1, e2):
	// 		case EField(e, field):
	// 		case EParenthesis(e):
	// 		case EObjectDecl(fields):
	// 		case EArrayDecl(values):
	// 		case ECall(e, params):
	// 		case EUnop(op, postFix, e):
	// 		case EVars(vars):

	// 		case EBlock(exprs):
	// 		case EFor(it, expr):
	// 		case EIf(econd, eif, eelse):
	// 		case EWhile(econd, e, normalWhile):
	// 		case ESwitch(e, cases, edef):

	// 		case EReturn(e): typeof(e);
	// 		case EBreak: TVoid;
	// 		case EContinue: TVoid;

	// 		case EDisplay(e, displayKind): cast null;
	// 		case ETernary(econd, eif, eelse):
	// 		case EMeta(s, e):
	// 		default: throw "unsupported expression";
	// 	}
	// 	switch e {
	// 		case _.expr => EBinop(op, e1, e2):
	// 			var t = typeof(e1);
	// 			if (unify(t, typeof(e1)))
	// 				return t
	// 			else
	// 				throw "assert";

	// 		case _:
	// 			throw "untyped expr";
	// 	}
	// }

	static function toType(c:ComplexType) {
		return switch c {
            // @formatter:off
            case macro:Bool: TBool;
            case macro:Int: TInt;
            case macro:Float: TFloat;

            // VecX<T:Bool | Int | Float = Float> 
            case macro:Vec2: TVec2(TFloat);
            case macro:Vec3: TVec3(TFloat);
            case macro:Vec4: TVec4(TFloat);
            case macro:Vec2<$t>: TVec2(toType(t));
            case macro:Vec3<$t>: TVec3(toType(t));
            case macro:Vec4<$t>: TVec4(toType(t));

            // MatX<T:Bool | Int | Float = Float> 
            case macro:Mat2: TMat2(TFloat);
            case macro:Mat3: TMat3(TFloat);
            case macro:Mat4: TMat4(TFloat);
            case macro:Mat2<$t>: TMat2(toType(t));
            case macro:Mat3<$t>: TMat3(toType(t));
            case macro:Mat4<$t>: TMat4(toType(t));
            // @formatter:on
			// case TPath(p):
			// case TFunction(args, ret):
			// case TAnonymous(fields):
			// case TParent(t):
			// case TExtend(p, fields):
			// case TOptional(t):
			// case TNamed(n, t):
			default:
				throw "unsupported type";
		}
	}
}
