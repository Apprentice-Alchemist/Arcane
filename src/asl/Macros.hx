package asl;

import asl.Ast.FunType;
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;

class Macros {
	#if macro
	public static function buildShader() {
		var fields = Context.getBuildFields();
		var cls = Context.getLocalClass().get();
		var name:String;
		{
			var a = cls.pack;
			a.push(cls.name);
			name = StringTools.replace(a.join(""), ".", "_");
		}
		if(cls.meta.has(":vertex")) {
			var vert_string = cls.meta.extract(":vertex")[0].params[0].getValue();
			fields.push({
				name: "get_vertex_src",
				kind: FFun({
					args: [],
					expr: macro return $v{makeShader(name, vert_string, true)}
				}),
				pos: cls.pos,
				access: [AOverride]
			});
		}
		if(cls.meta.has(":fragment")) {
			var frag_string = cls.meta.extract(":fragment")[0].params[0].getValue();
			fields.push({
				name: "get_fragment_src",
				kind: FFun({
					args: [],
					expr: macro return $v{makeShader(name, frag_string, false)}
				}),
				pos: cls.pos,
				access: [AOverride]
			});
		}

		// var fragment_field = Lambda.find(fields, item -> item.name == "FRAGMENT_SRC");
		// assert(fragment_field != null, () -> Context.error('Did not find field FRAGMENT_SRC.', cls.pos));
		// fields.remove(fragment_field);
		// var vertex_field = Lambda.find(fields, item -> item.name == "VERTEX_SRC");
		// assert(vertex_field != null, () -> Context.error('Did not find field VERTEX_SRC.', cls.pos));
		// fields.remove(vertex_field);

		// var fragment_expr = switch fragment_field.kind {
		// 	case FVar(t, e): e;
		// 	default: Context.error('Expected FVar(t, e) but got ${fragment_field.kind}', fragment_field.pos);
		// }

		// var vertex_expr = switch vertex_field.kind {
		// 	case FVar(t, e): e;
		// 	default: Context.error('Expected FVar(t, e) but got ${vertex_field.kind}', vertex_field.pos);
		// }
		// cls.meta.add("vertex_src", [Parser.parse(vertex_expr)], cls.pos);
		// cls.meta.add("fragment_src", [Parser.parse(fragment_expr)], cls.pos);
		return fields;
	}

	public static function makeShader(name:String, b:String, vertex:Bool):String {
		#if !display
		if(haxe.macro.Context.defined("display"))
			return b;
		var input:String = ".tmp/" + name + "." + (vertex ? "vert" : "frag") + ".glsl";
		var output:String = ".tmp/" + name + "." + (vertex ? "vert" : "frag") + (haxe.macro.Context.defined("js") ? ".essl" : ".d3d11");
		if(sys.FileSystem.exists(input) && sys.io.File.getContent(input) == b && sys.FileSystem.exists(output)) {
			var s = sys.io.File.getBytes(output).toHex();
			return s;
		}
		sys.io.File.saveContent(input, b);
		var ret = 1;
		if(haxe.macro.Context.defined("js"))
			ret = Sys.command("krafix", ["essl", input, output, ".tmp", "windows","--quiet"]);
		else
			ret = Sys.command("krafix", ["d3d11", input, output, ".tmp", "windows","--quiet"]);
		if(ret != 0)
			haxe.macro.Context.error("Shader compilation failed.", haxe.macro.Context.currentPos());
		var s = sys.io.File.getBytes(output).toHex();
		return s;
		#else
		return b;
		#end
	}
	#end
}
