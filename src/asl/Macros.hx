package asl;

import haxe.io.Bytes;
#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

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
		makeShader(name, cls.meta.extract(":vertex")[0].params[0].getValue(), cls.meta.extract(":fragment")[0].params[0].getValue());
		fields.push({
			name: "new",
			kind: FFun({
				args: [],
				expr: macro super($v{name})
			}),
			pos: (macro null).pos,
			access: [APublic]
		});
		return fields;
	}

	static function makeShader(name:String, vertex:String, fragment:String) {
		final compiler = arcane.internal.Macros.getShaderCompiler();
		compiler.compile(name, Bytes.ofString(vertex), true);
		compiler.compile(name, Bytes.ofString(fragment), false);
	}
	#end
}
