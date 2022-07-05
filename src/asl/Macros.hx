package asl;

import haxe.macro.Printer;
// import arcane.internal.html5.WebAudioDriver.AudioBuffer;
import haxe.macro.Compiler;
import haxe.Serializer;
import haxe.io.Bytes;
#if macro
import haxe.macro.Expr;
import haxe.macro.Context.*;

using haxe.macro.Tools;
#end

class Macros {
	public static macro function shader(e) {
		return macro $e;
	}

	#if macro

	public static function buildShader() {
		var fields = getBuildFields();
		var cls = getLocalClass().get();
		var name:String;
		{
			var a = cls.pack;
			a.push(cls.name);
			name = StringTools.replace(a.join(""), ".", "_");
		}
		final vertex = if (cls.meta.has(":vert")) asl.Typer.makeModule(name, cls.meta.extract(":vert")[0].params[0], Vertex) else null;
		final fragment = if (cls.meta.has(":frag")) asl.Typer.makeModule(name, cls.meta.extract(":frag")[0].params[0], Fragment) else null;
		final compute = if (cls.meta.has(":comp")) asl.Typer.makeModule(name, cls.meta.extract(":comp")[0].params[0], Compute) else null;

		final compiler = arcane.internal.Macros.getShaderCompiler();
		compiler(name, Bytes.ofString(GlslOut.toGlsl(vertex #if kinc, true #end)), Bytes.ofString(GlslOut.toGlsl(fragment #if kinc,
			true #end)), compute == null ? null : Bytes.ofString(GlslOut.toGlsl(compute #if kinc, true #end)));
		// if (fragment != null)
		// 	compiler(name, Bytes.ofString(GlslOut.toGlsl(fragment #if kinc, true #end)), Fragment);
		// if (compute != null)
		// 	compiler(name, Bytes.ofString(GlslOut.toGlsl(fragment #if kinc, true #end)), Compute);

		fields.push({
			name: "new",
			kind: FFun({
				args: [],
				expr: macro super($v{name}, $v{vertex}, $v{fragment}, $v{compute})
			}),
			pos: (macro null).pos,
			access: [APublic]
		});
		return fields;
	}

	static function makeShader(name:String, vertex:String, fragment:String) {
		// trace(vertex,fragment);
	}
	#end
}
