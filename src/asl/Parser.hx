package asl;

import haxe.macro.Expr;
using haxe.macro.ExprTools;

class Parser {
	static function error(msg:String,pos:haxe.macro.Expr.Position){
		#if macro
		haxe.macro.Context.error(msg,pos);
		#else
		throw msg;
		#end
	}
	public static function parse(expr:haxe.macro.Expr) {
		var exprs = switch expr.expr {
			case EBlock(exprs): exprs;
			default: throw "Did not expect " + expr.expr;
		}
		var variables:Array<Dynamic> = [];
		var functions:Array<Dynamic> = [];
		function iter(expr:Expr,curmeta:Array<MetadataEntry>){
			switch expr.expr {
				case EMeta(s, e):
					expr.iter(iter.bind(_,curmeta.concat([s])));
				case EVars([v]):
					variables.push({
						type: v.type,
						meta: curmeta.concat(v.meta == null ? [] : v.meta),
						name: v.name
					});
				case EFunction(FNamed(name,false), f):
					functions.push({
						name: name,
						expr: f.expr,
						ret: f.ret,
						args: f.args
					});
				default: error("Unsupported expression",expr.pos);
					
			}
		}
		expr.iter(iter.bind(_,[]));
		// trace(variables);
		// trace(functions);
	}
}
