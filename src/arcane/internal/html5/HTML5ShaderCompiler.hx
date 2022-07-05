package arcane.internal.html5;

import asl.Ast.ShaderStage;
import haxe.io.Bytes;
#if macro
import sys.FileSystem;
import sys.io.File;
import haxe.macro.Context;
import arcane.internal.Macros;

using StringTools;
#end

class HTML5ShaderCompiler {
	static function command(name:String, args:Array<String>) {
		#if macro
		if (Sys.command(name, args) != 0) {
			Context.fatalError("Shader compilation error, command : " + name, Context.currentPos());
		}
		#end
	}

	public static function compile(id:String, vertex:haxe.io.Bytes, fragment:haxe.io.Bytes, compute:haxe.io.Bytes) {
		if (vertex != null) {
			compileSingle(id, vertex, Vertex);
		}
		if (fragment != null) {
			compileSingle(id, fragment, Fragment);
		}
		if (compute != null) {
			compileSingle(id, compute, Compute);
		}
	}

	public static function compileSingle(id:String, source:Bytes, stage:ShaderStage):Void {
		#if macro
		if (Context.defined("display") || #if display true #else false #end)
			return;
		var temp = Macros.getTempDir();
		final stage = switch stage {
			case Vertex: "vert";
			case Fragment: "frag";
			case Compute: "comp";
		}
		FileSystem.createDirectory(temp);
		File.saveBytes('$temp/$id.$stage', source);
		command("glslc", [
			"-Dopengl",
			'-fshader-stage=$stage',
			"-fauto-map-locations",
			// "-fauto-bind-uniforms",
			"--target-env=opengl",
			"-o",
			'$temp/$id.$stage.spv',
			'$temp/$id.$stage',
		]);

		command("spirv-cross", [
			'$temp/$id.$stage.spv',
			"--es",
			"--version",
			"100",
			"--glsl-emit-ubo-as-plain-uniforms",
			"--output",
			'$temp/$id-webgl1.$stage',
		]);
		command("spirv-cross", [
			'$temp/$id.$stage.spv',
			"--es",
			"--version",
			"300",
			"--output",
			'$temp/$id-webgl2.$stage',
		]);

		var _id = '$id-$stage';
		if (Context.defined("wgpu_externs")) {
			command("glslc", [
				'-fshader-stage=$stage',
				"-fauto-map-locations",
				"-o",
				'$temp/$id.$stage-naga.spv',
				'$temp/$id.$stage'
			]);
			command("spirv-val", ['$temp/$id.$stage-naga.spv']);
			command("naga", ['$temp/$id.$stage-naga.spv', '$temp/$id.$stage.wgsl', "--validate", "31"]);
			Context.addResource('$_id-webgpu', File.getBytes('$temp/$id.$stage.wgsl'));
		}
		Context.addResource('$_id-default', File.getBytes('$temp/$id-webgl1.$stage'));
		Context.addResource('$_id-webgl2', File.getBytes('$temp/$id-webgl2.$stage'));
		#end
	}
}
