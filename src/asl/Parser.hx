package asl;

import haxe.macro.Expr;

using haxe.macro.ExprTools;

typedef ParsedShader = {
	var variables:Array<{
		var name:String;
		var meta:Array<MetadataEntry>;
		var type:ComplexType;
	}>;
	var functions:Array<{
		var name:String;
		var ret:Null<ComplexType>;
		var expr:Expr;
		var args:Array<FunctionArg>;
	}>;
}

@:nullSafety
class Parser {
	static function error(msg:String, pos:haxe.macro.Expr.Position) {
		#if macro
		haxe.macro.Context.error(msg, pos);
		#else
		throw msg;
		#end
	}

	public static function parse(expr:haxe.macro.Expr) {
		var exprs = switch expr.expr {
			case EBlock(exprs): exprs;
			default: throw "Expected a block, not a" + expr.expr;
		}
		var parsed_shader:ParsedShader = {
			variables: [],
			functions: []
		}
		function iter(expr:Expr, curmeta:Array<MetadataEntry>) {
			switch expr.expr {
				case EMeta(s, e):
					expr.iter(iter.bind(_, curmeta.concat([s])));
				case EVars([v]):
					parsed_shader.variables.push({
						type: v.type,
						meta: curmeta.concat(v.meta == null ? [] : v.meta),
						name: v.name
					});
				case EFunction(FNamed(name, false), f):
					parsed_shader.functions.push({
						name: name,
						expr: f.expr,
						ret: f.ret,
						args: f.args
					});
				default:
					error("Unsupported expression", expr.pos);
			}
		}
		for (e in exprs)
			iter(e, []);
		return parsed_shader;
	}
}
