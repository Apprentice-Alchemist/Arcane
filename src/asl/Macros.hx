package asl;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

class Macros {
	private static inline function assert(cond:Bool, err:Void->Void)
		if(!cond)
			err();

	#if macro
	public static function buildShader() {
		var fields = Context.getBuildFields();
		var cls = Context.getLocalClass().get();

		var fragment_field = Lambda.find(fields, item -> item.name == "FRAGMENT_SRC");
		assert(fragment_field != null, () -> Context.error('Did not find field FRAGMENT_SRC.', cls.pos));
		fields.remove(fragment_field);
		var vertex_field = Lambda.find(fields, item -> item.name == "VERTEX_SRC");
		assert(vertex_field != null, () -> Context.error('Did not find field VERTEX_SRC.', cls.pos));
		fields.remove(vertex_field);
		
		var fragment_expr = switch fragment_field.kind {
			case FVar(t, e): e;
			default: Context.error('Expected FVar(t, e) but got ${fragment_field.kind}', fragment_field.pos);
		}

		var vertex_expr = switch vertex_field.kind {
			case FVar(t, e): e;
			default: Context.error('Expected FVar(t, e) but got ${vertex_field.kind}', vertex_field.pos);
		}
		Parser.parse(vertex_expr);
		Parser.parse(fragment_expr);
		cls.meta.add("src", [], cls.pos);

		return fields;
	}
	#end
}
