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

	static function unify(a:Type, b:Type):Bool {
		if (a == b)
			return true;
		return switch [a, b] {
			case [TVec2(a), TVec2(b)] if (a == b): true;
			case [TVec3(a), TVec3(b)] if (a == b): true;
			case [TVec4(a), TVec4(b)] if (a == b): true;

			case [TVec2(a), TVec2(b)] if (a == b): true;
			case [TVec2(a), TVec2(b)] if (a == b): true;
			case [TVec2(a), TVec2(b)] if (a == b): true;
			case [_, _]: false;
		}
	}

	static function typeof(e:Expr) {
		switch e {
			case macro $a + $b:
				return typeof(a);

			case _:
				throw "untyped expr";
		}
	}

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
