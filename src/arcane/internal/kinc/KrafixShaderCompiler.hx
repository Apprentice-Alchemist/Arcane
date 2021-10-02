package arcane.internal.kinc;

import asl.Ast.ShaderStage;
import haxe.io.Bytes;
#if macro
import sys.io.File;
import arcane.internal.Macros.cmd;
import arcane.internal.Macros.getTempDir;
import haxe.macro.Context;
#end

class KrafixShaderCompiler implements IShaderCompiler {
	public function new() {}

	public function compile(id:String, source:Bytes, stage:ShaderStage):Void {
		#if macro
		if (Context.defined("display"))
			return;
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
		final ext = switch stage {
			case Vertex: "vert";
			case Fragment: "frag";
			case Compute: "comp";
		}
		var input = '$tempdir/$id.$ext.glsl';
		File.saveBytes(input, source);
		var output = '$tempdir/$id-$platform.$ext.$lang';
		var data = '$tempdir/$id-$ext.data';
		var ret = cmd(k, [lang, input, output, tempdir, platform]);

		if (ret.code != 0)
			haxe.macro.Context.error("Shader compilation failed : \n" + ret.stderr + "\n" + ret.stdout.toString(), haxe.macro.Context.currentPos());
		Context.addResource('$id-$ext-default', File.getBytes(output));
		#end
	}
}
