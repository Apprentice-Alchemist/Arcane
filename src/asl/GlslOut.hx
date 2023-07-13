package asl;

import asl.Typer.Pos;
import asl.Ast.TypedExpr;
import asl.Ast.Type;
import asl.Ast.ShaderModule;

class GlslOut {
	public static function escape(s:String) {
		return switch s {
			case "texture": "_texture";
			case var s: s;
		}
	}

	static function typeToGlsl(t:Type) {
		return switch t {
			case TMonomorph(r):
				switch r.value {
					case null: Typer.error("Unresolved monomorph", (macro null).pos);
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
		buf.add("#ifdef VULKAN\n");
		buf.add("#define gl_InstanceID gl_InstanceIndex\n");
		buf.add("#define texture(t,uv) texture(sampler2D(t,t##_sampler),uv)\n");
		buf.add("#endif\n");
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
		if (!krafix && module.uniforms.filter(f -> f.t != TSampler2D).length > 0)
			buf.add('layout(binding = 0) uniform M${module.stage.match(Vertex) ? "vert" : "frag"} {\n');
		for (uniform in module.uniforms.filter(f -> f.t != TSampler2D)) {
			if (krafix)
				buf.add("uniform ");
			var ssize = "";
			var t = switch uniform.t {
				case TArray(t, size):
					ssize = '[$size]';
					t;
				case var t: t;
			}
			buf.add(typeToGlsl(t));
			buf.add(" " + escape(uniform.name));
			buf.add(ssize);
			buf.add(";\n");
		}
		if (!krafix && module.uniforms.filter(f -> f.t != TSampler2D).length > 0)
			buf.add("};\n");
		var curbinding = 0;
		for (uniform in module.uniforms.filter(f -> f.t == TSampler2D)) {
			final binding = switch uniform.kind {
				case Uniform(binding): binding;
				case _: throw "assert";
			}
			buf.add("#ifdef VULKAN\n");
			buf.add('layout(set = 0, binding = ${binding + curbinding}) uniform ');
			buf.add("texture2D");
			buf.add(" " + escape(uniform.name));
			buf.add(";\n");
			buf.add('layout(set = 0, binding = ${binding + curbinding + 1}) uniform ');
			buf.add("sampler");
			buf.add(" " + escape(uniform.name) + "_sampler");
			buf.add(";\n");
			buf.add("#else\n");
			buf.add('layout(binding = ${binding}) uniform ');
			buf.add("sampler2D");
			buf.add(" " + escape(uniform.name));
			buf.add(";\n");
			buf.add("#endif\n");
			curbinding++;
		}
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
					case null: throw "assert";
				} else escape(v.name);
			case TArray(e1, e2): convExpr(e1) + "[" + convExpr(e2) + "]";
			case TBinop(op, e1, e2): convExpr(e1) + " " + (new haxe.macro.Printer()).printBinop(op) + " " + convExpr(e2);
			case TField(e, TSwiz(components)): convExpr(e) + "." + [
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
			case TField(e, fa): throw "TODO TField";
			case TParenthesis(e): '(${convExpr(e)})';
			case TObjectDecl(fields): throw "TODO";
			case TArrayDecl(el): throw "TODO";
			case TCallBuiltin(b, el):
				(switch b {
					case BuiltinVec4(t): "vec4";
					case BuiltinVec3(t): "vec3";
					case BuiltinVec2(t): "vec2";
					case BuiltinSampleTexture: "texture";
					case BuiltinMix: "mix";
					case BuiltinNormalize: "normalize";
					case BuiltinMax: "max";
					case BuiltinPow: "pow";
					case BuiltinDot: "dot";
					case BuiltinReflect: "reflect";
					case BuiltinTranspose: "transpose";
					case BuiltinInverse: "inverse";
					case BuiltinMat3: "mat3";
				}) + "(" + [for (e in el) convExpr(e)].join(", ") + ")";
			case TCall(e, el):
				convExpr(e) + "(" + [for (e in el) convExpr(e)].join(", ") + ")";
			case TUnop(op, postFix, e):
				var op = (new haxe.macro.Printer()).printUnop(op);
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
		}
	}
}
