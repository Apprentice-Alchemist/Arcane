package arcane.internal.kinc;

import haxe.io.Bytes;
#if macro
import sys.io.File;
import arcane.internal.Macros.cmd;
import arcane.internal.Macros.getTempDir;
import haxe.macro.Context;
#end

class KrafixShaderCompiler implements IShaderCompiler {
	public function new() {}

	public function compile(id:String, source:Bytes, vertex:Bool):Void {
		#if macro
		if (Context.defined("display"))
			return;
		if (false && Context.defined("vulkan")) {
			var s = Macros.cmd("glslc", [
				'-fshader-stage=${vertex ? "vert" : "frag"}',
				"--target-env=vulkan",
				"-o",
				"-",
				"-"
			], source);
			// if (lang == "spirv") {
			// trace(cmd("spirv-dis", [
			// 	// "-o",
			// 	// "out/shaders/" + id + (vertex ? ".vert.dis" : ".frag.dis"),
			// 	"--comment",
			// 	"-"]).stdout,s.stdout);
			// }
			// if (lang == "spirv")
			// File.copy(output, "out/shaders/" + id + (vertex ? ".vert.spv" : ".frag.spv"));
			Context.addResource('$id-${vertex ? "vert" : "frag"}-default', s.stdout);
		} else {
			var platform:String = if (Context.defined("html5") || Context.defined("js")) {
				"html5";
			} else if (Context.defined("android")) {
				"android";
			} else if (Context.defined("ios")) {
				"ios";
			} else if (Context.defined("console")) {
				Context.definedValue("console");
			} else switch Sys.systemName() {
				case "Windows": "windows";
				case "Mac": "osx";
				case _: "linux";
			}
			var lang = switch platform {
				case "windows": if (Context.defined("opengl")) "glsl" else if (Context.defined("vulkan")) "spirv" else "d3d11";
				case "html5": if (Context.defined("webgpu")) "spirv" else "essl";
				case "osx" | "ios": "metal";
				case "linux" | "android": if (Context.defined("vulkan")) "spirv" else "essl";
				case var p: p; // consoles
			}
			var a = Macros.findArcane();
			var k = haxe.io.Path.normalize(haxe.io.Path.join([
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
			var tempdir = getTempDir();
			var input = '$tempdir/$id.${vertex ? "vert" : "frag"}.glsl';
			File.saveBytes(input, source);
			var output = '$tempdir/$id.${vertex ? "vert" : "frag"}.$platform.$lang';
			var data = '$tempdir/$id.${vertex ? "vert" : "frag"}.data';
			var ret = cmd(k, [lang, input, output, tempdir, platform]);

			if (ret.code != 0)
				haxe.macro.Context.error("Shader compilation failed : \n" + ret.stderr + "\n" + ret.stdout.toString(), haxe.macro.Context.currentPos());
			Context.addResource('$id-${vertex ? "vert" : "frag"}-default', File.getBytes(output));
		}
		#end
	}

	// static function compile(name:String, b:String, lang:String, platform:String, vertex:Bool):Map<String, String> {
	// 	function getData() {
	// 		var f = File.getContent(data);
	// 		var d = StringTools.replace(f, "\r\n", "\n").split("\n");
	// 		var uniforms = [];
	// 		var inputs = [];
	// 		for (p in d) {
	// 			var t = p.substr(1).split(":");
	// 			switch t[0] {
	// 				case "uniform" if (t[0].substring(0, 3) != "gl_"):
	// 					uniforms.push({name: t[1], type: t[2]});
	// 				case "input" if (vertex):
	// 					inputs.push({name: t[1], type: t[2]});
	// 				case _:
	// 					continue;
	// 			}
	// 		}
	// 		return {
	// 			uniforms: uniforms,
	// 			inputs: inputs,
	// 			data: sys.io.File.getBytes(if (platform == "html5") '$shader_bin/$name-webgl2.${vertex ? "vert" : "frag"}.$platform.$lang' else output).toHex()
	// 		}
	// 	}
	// 	if (!haxe.macro.Context.defined("shader-clean")
	// 		&& sys.FileSystem.exists(input)
	// 		&& sys.io.File.getContent(input) == b
	// 		&& sys.FileSystem.exists(data)) {
	// 		return [];
	// 	}
	// 	if (!FileSystem.exists(shader_bin))
	// 		FileSystem.createDirectory(shader_bin);
	// 	sys.io.File.saveContent(input, b);
	// 	var a = arcane.internal.Macros.findArcane();
	// 	// todo console compilers
	// 	sys.io.File.saveContent(data, ret.err);
	// 	return [];
	// }
	// static function makeShader(name:String, b:String, vertex:Bool) {
	// 	return compile(name, b, lang, platform, vertex).get("default");
	// }
}
