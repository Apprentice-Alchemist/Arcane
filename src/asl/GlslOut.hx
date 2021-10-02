package asl;

import asl.Typer.Pos;
import asl.Ast.TypedExpr;
import asl.Ast.Type;
import asl.Ast.ShaderModule;

class GlslOut {
	static function typeToGlsl(t:Type) {
		return switch t {
			case TMonomorph(r):
				switch r.value {
					case null: Typer.error("Unresolved monomorph",(macro null).pos);
					case var t: typeToGlsl(t);
				}
			case TVoid:
				"void";
			case TBool:
				"bool";
			case TInt:
				"int";
			case TFloat:
				"float";
			case TVec(t, size):
				(switch t {
					case TBool: "b";
					case TInt: "i";
					case TFloat: "";
					case _: throw "assert";
				}) + "vec" + size;
			case TMat(t, size):
				"mat" + size;
			case TArray(t, size):
				typeToGlsl(t) +
				'[$size]';
			case TStruct(fields):
				throw "todo";
			case TSampler2D:
				"sampler2D";
			case TSampler2DArray:
				"sampler2DArray";
			case TSamplerCube:
				"samplerCube";
		}
	}

	public static function toGlsl(module:ShaderModule, krafix = false) {
		final buf = new StringBuf();
		buf.add("#version 450\n");
		for (input in module.inputs)
			if (input.builtin == null) {
				buf.add("in ");
				buf.add(typeToGlsl(input.t));
				buf.add(" " + input.name);
				buf.add(";\n");
			}

		for (output in module.outputs)
			if (output.builtin == null) {
				buf.add("out ");
				buf.add(typeToGlsl(output.t));
				buf.add(" " + output.name);
				buf.add(";\n");
			}
		if (!krafix && module.uniforms.length > 0)
			buf.add("uniform M {\n");
		for (uniform in module.uniforms) {
			buf.add("uniform ");
			var ssize = "";
			var t = switch uniform.t {
				case TArray(t, size):
					ssize = '[$size]';
					t;
				case var t: t;
			}
			buf.add(typeToGlsl(t));
			buf.add(" " + uniform.name);
			buf.add(ssize);
			buf.add(";\n");
		}
		if (!krafix && module.uniforms.length > 0)
			buf.add("};\n");
		for (func in module.functions) {
			buf.add(typeToGlsl(func.ret));
			buf.add(" " + func.name + "(");
			for (idx => arg in func.args) {
				buf.add(typeToGlsl(arg.t));
				buf.add(" " + arg.name);
				if (idx < func.args.length - 1)
					buf.add(",");
			}
			buf.add(") ");
			buf.add(convExpr(func.expr));
		}
		return buf.toString();
	}

	static function convExpr(e:TypedExpr):String {
		return switch e.expr {
			case TConst(c): switch c {
					case TInt(i): Std.string(i);
					case TFloat(s): s + "f";
					case TBool(b): b ? "true" : "false";
					case _: throw "assert";
				}
			case TLocal(v):
				if (v.builtin != null) switch v.builtin {
					case position: "gl_Position";
					case instanceIndex: "gl_InstanceID";
				} else v.name;
			case TArray(e1, e2): convExpr(e1) + "[" + convExpr(e2) + "]";
			case TBinop(op, e1, e2): convExpr(e1) + " " + (inline new haxe.macro.Printer()).printBinop(op) + " " + convExpr(e2);
			case TField(e, fa): throw "TODO";
			case TParenthesis(e): '(${convExpr(e)})';
			case TObjectDecl(fields): throw "TODO";
			case TArrayDecl(el): throw "TODO";
			case TCallBuiltin(b, el):
				(switch b {
					case BuiltinVec4(t): "vec4";
					case BuiltinVec3(t): "vec3";
					case BuiltinVec2(t): "vec2";
				}) + "(" + [for (e in el) convExpr(e)].join(", ") + ")";
			case TCall(e, el):
				convExpr(e) + "(" + [for (e in el) convExpr(e)].join(", ") + ")";
			case TUnop(op, postFix, e):
				var op = (inline new haxe.macro.Printer()).printUnop(op);
				postFix ? convExpr(e) + op : op + convExpr(e);
			case TVar(v, expr):
				typeToGlsl(v.t) + " " + v.name + (expr == null ? "" : " = " + convExpr(expr));
			case TBlock(el): "{\n" + [for (e in el) convExpr(e) + ";\n"].join("") + "}\n";
			case TFor(v, e1, e2): throw "TODO";
			case TIf(econd, eif, eelse):
				"if(" + convExpr(econd) + ")" + convExpr(eif) + if (eelse != null) "else" + convExpr(eelse) else "";
			case TWhile(econd, e, normalWhile):
				if (normalWhile) {
					"while(" + convExpr(econd) + ") " + convExpr(e);
				} else {
					"do " + convExpr(e) + "while(" + convExpr(econd) + ");";
				}
			case TReturn(e): "return" + (e == null ? "" : " " + convExpr(e));
			case TBreak: "break";
			case TContinue: "continue";
			case TMeta(_, e1): convExpr(e1);
			case TSwiz(e, components): convExpr(e) + "." + [
					for (comp in components)
						switch comp {
							case X:
								"x";
							case Y:
								"y";
							case Z:
								"z";
							case W:
								"w";
						}
				].join("");
		}
	}
}
