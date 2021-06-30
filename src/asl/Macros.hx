package asl;

import haxe.io.Path;
#if macro
import sys.io.Process;
import haxe.SysTools;
import sys.io.File;
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
		if (!cls.meta.has(":vertex"))
			Context.error("Shader does not have @:vertex data.", cls.pos);
		if (!cls.meta.has(":fragment"))
			Context.error("Shader does not have @:fragment data.", cls.pos);

		var vertex_data = makeShader(name, cls.meta.extract(":vertex")[0].params[0].getValue(), true);
		var fragment_data = makeShader(name, cls.meta.extract(":fragment")[0].params[0].getValue(), false);

		var uniforms = vertex_data.uniforms.concat(fragment_data.uniforms);
		var inputs = vertex_data.inputs;

		// for(u in uniforms) {}
		// Context.addResource()
		fields.push({
			name: "get_vertex_src",
			kind: FFun({
				args: [],
				expr: macro return $v{vertex_data.data}
			}),
			pos: cls.pos,
			access: [AOverride]
		});

		fields.push({
			name: "get_fragment_src",
			kind: FFun({
				args: [],
				expr: macro return $v{fragment_data.data}
			}),
			pos: cls.pos,
			access: [AOverride]
		});
		return fields;
	}

	static function cmd(cmd:String, args:Array<String>) {
		var proc = new sys.io.Process(cmd, args);
		var code = proc.exitCode();
		var output = proc.stdout.readAll().toString();
		var err = proc.stderr.readAll().toString();
		proc.close();
		return {
			code: code,
			out: output,
			err: err
		}
	}

	static function makeShader(name:String, b:String, vertex:Bool) {
		var platform:String = if (Context.defined("js")) "html5" else if (Context.defined("android")) "android" else if (Context.defined("ios")) "ios" else
			if (Context.defined("console")) Context.definedValue("console") else switch Sys.systemName() {
			case "Windows": "windows";
			case "Mac": "osx";
			case _: "linux";
		}

		var lang = switch platform {
			case "windows": if (Context.defined("opengl")) "glsl" else "d3d11";
			case "html5": "essl";
			case "osx" | "ios": "metal";
			case "linux" | "android": if (Context.defined("vulkan")) "spirv" else "essl";
			case var p: p; // consoles
		}

		var shader_bin = Context.defined("asl-shader-bin") ? Context.definedValue("asl-shader-bin") : ".tmp";
		var input:String = '$shader_bin/$name.${vertex ? "vert" : "frag"}.glsl';
		var output = '$shader_bin/$name.${vertex ? "vert" : "frag"}.$platform.$lang';
		var data = '$shader_bin/$name.${vertex ? "vert" : "frag"}.data';

		function getData() {
			var f = File.getContent(data);
			var d = StringTools.replace(f, "\r\n", "\n").split("\n");
			var uniforms = [];
			var inputs = [];
			for (p in d) {
				var t = p.substr(1).split(":");
				switch t[0] {
					case "uniform" if (t[0].substring(0, 3) != "gl_"):
						uniforms.push({name: t[1], type: t[2]});
					case "input" if (vertex):
						inputs.push({name: t[1], type: t[2]});
					case _:
						continue;
				}
			}
			return {
				uniforms: uniforms,
				inputs: inputs,
				data: sys.io.File.getBytes(if (platform == "html5") '$shader_bin/$name-webgl2.${vertex ? "vert" : "frag"}.$platform.$lang' else output).toHex()
			}
		}

		if (!haxe.macro.Context.defined("shader-clean")
			&& sys.FileSystem.exists(input)
			&& sys.io.File.getContent(input) == b
			&& sys.FileSystem.exists(data)) {
			return getData();
		}

		if (!FileSystem.exists(shader_bin))
			FileSystem.createDirectory(shader_bin);
		sys.io.File.saveContent(input, b);
		var a = arcane.internal.Macros.findArcane();
		// todo console compilers
		var k = Path.normalize(Path.join([
			a,
			"tools",
			"krafix",
			switch Sys.systemName() {
				case "Windows":
					"krafix.exe";
				case "Mac":
					"krafix-osx";
				case "Linux":
					"krafix-linux64"; // todo linuxarm and linux-aarch64 somehow
				case "BSD":
					"krafix-freebsd";
				case _:
					throw "assert";
			}]));

		var ret = cmd(k, [lang, input, output, shader_bin, platform]);
		if (ret.code != 0)
			haxe.macro.Context.error("Shader compilation failed : \n" + ret.out, haxe.macro.Context.currentPos());
		sys.io.File.saveContent(data, ret.err);
		return getData();
	}
	#end
}
