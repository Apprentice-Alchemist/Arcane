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
	}

	static function makeShader(name:String, b:String, vertex:Bool):String {
		#if !display
		if (haxe.macro.Context.defined("display"))
			return b;
		var platform = if (Context.defined("js")) "html5" else switch Sys.systemName() {
			case "Windows": "windows";
			case "Mac": "osx";
			case s: "linux";
		}

		var lang = switch platform {
			case "windows": if(Context.defined("opengl")) "glsl" else "d3d11";
			case "html5": "essl";
			case "mac": "metal";
			case "linux": if(Context.defined("vulkan")) "spirv" else "essl";
			case _: throw "unkown platform " + platform;
		}

		var shader_bin = Context.defined("asl-shader-bin") ? Context.definedValue("asl-shader-bin") : ".tmp";
		var input:String = '$shader_bin/$name.${vertex ? "vert" : "frag"}.glsl';
		var output = '$shader_bin/$name.${vertex ? "vert" : "frag"}.$platform.$lang';

		if (!haxe.macro.Context.defined("shader-clean")
			&& sys.FileSystem.exists(input)
			&& sys.io.File.getContent(input) == b
			&& sys.FileSystem.exists(output)) {
			var s = sys.io.File.getBytes(output).toHex();
			return s;
		}
		if (!FileSystem.exists(shader_bin))
			FileSystem.createDirectory(shader_bin);
		sys.io.File.saveContent(input, b);
		var ret = Sys.command("krafix", [lang, input, output, shader_bin, platform #if (!asl_debug), "--quiet" #end]);
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
