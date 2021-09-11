package arcane.internal.html5;

import haxe.io.Bytes;
#if macro
import sys.io.File;
import haxe.macro.Context;
import arcane.internal.Macros;

using StringTools;
#end

class HTML5ShaderCompiler implements IShaderCompiler {
	public function new() {}

	public function compile(id:String, source:Bytes, vertex:Bool):Void {
		#if (macro&&!display)
		if (Context.defined("display"))
			return;
		var temp = Macros.getTempDir();
		var s = Macros.cmd("glslc", [
			'-fshader-stage=${vertex ? "vert" : "frag"}',
			"-fauto-map-locations",
			"-fauto-bind-uniforms",
			"--target-env=opengl",
			"-o",
			"-",
			"-"
		], source);
		if (s.code != 0 || s.stderr.trim() != "") {
			Sys.println("Error while compiling shader " + id);
			Sys.println(s.stderr);
			Sys.exit(1);
		}
		var webgl1 = Macros.cmd("spirv-cross", ["--es", "--version", "100", "--glsl-emit-ubo-as-plain-uniforms", "-"], s.stdout);
		var webgl2 = Macros.cmd("spirv-cross", ["--es", "--version", "300", "--glsl-emit-ubo-as-plain-uniforms", "-"], s.stdout);
		if (webgl1.code != 0 || webgl1.stderr.trim() != "") {
			Sys.println("Error while compiling shader " + id);
			Sys.println(webgl1.stderr);
			Sys.exit(1);
		}
		if (webgl2.code != 0 || webgl2.stderr.trim() != "") {
			Sys.println("Error while compiling shader " + id);
			Sys.println(webgl2.stderr);
			Sys.exit(1);
		}
		var webgpu = Macros.cmd("glslc", [
			'-fshader-stage=${vertex ? "vert" : "frag"}',
			"-fauto-map-locations",
			"-fauto-bind-uniforms",
			"--target-env=vulkan",
			"-Dgl_InstanceID=gl_InstanceIndex",
			"-o",
			'$temp/$id.${vertex ? "vert" : "frag"}.spv',
			"-"
		], source);
		if (webgpu.code != 0 || webgpu.stderr.trim() != "") {
			Sys.println("Error while compiling shader " + id);
			Sys.println(webgpu.stderr);
			Sys.exit(1);
		}
		Macros.cmd("naga", [
			'$temp/$id.${vertex ? "vert" : "frag"}.spv',
			'$temp/$id.${vertex ? "vert" : "frag"}.wgsl',"--validate"]);

		var _id = '$id-${vertex ? "vert" : "frag"}';
		Context.addResource('$_id-default', webgl1.stdout);
		Context.addResource('$_id-webgl2', webgl2.stdout);
		Context.addResource('$_id-webgpu', File.getBytes('$temp/$id.${vertex ? "vert" : "frag"}.wgsl'));
		#end
	}
}
