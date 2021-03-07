package asl;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;

using haxe.macro.Tools;
#end

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
		if (cls.meta.has(":vertex")) {
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
		if (cls.meta.has(":fragment")) {
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
		return fields;
		// Compiler
	}

	public static function makeShader(name:String, b:String, vertex:Bool):String {
		#if !display
		if (haxe.macro.Context.defined("display"))
			return b;
		var shader_bin = Context.defined("asl-shader-bin") ? Context.definedValue("asl-shader-bin") : ".tmp";
		var input:String = shader_bin + "/" + name + "." + (vertex ? "vert" : "frag") + ".glsl";
		var output:String = shader_bin + "/" + name + "." + (vertex ? "vert" : "frag") + (haxe.macro.Context.defined("js") ? ".essl" : ".d3d11");
		if (!haxe.macro.Context.defined("shader_clean")
			&& sys.FileSystem.exists(input)
			&& sys.io.File.getContent(input) == b
			&& sys.FileSystem.exists(output)) {
			var s = sys.io.File.getBytes(output).toHex();
			return s;
		}
		if (!FileSystem.exists(shader_bin))
			FileSystem.createDirectory(shader_bin);
		sys.io.File.saveContent(input, b);
		var ret = 1;
		if (haxe.macro.Context.defined("js"))
			ret = Sys.command("krafix", ["essl", input, output, shader_bin, "windows" #if (!asl_debug), "--quiet" #end]);
		else
			ret = Sys.command("krafix", ["d3d11", input, output, shader_bin, "windows" #if (!asl_debug), "--quiet" #end]);
		if (ret != 0)
			haxe.macro.Context.error("Shader compilation failed.", haxe.macro.Context.currentPos());
		var s = sys.io.File.getBytes(output).toHex();
		return s;
		#else
		return b;
		#end
	}
	#end
}
