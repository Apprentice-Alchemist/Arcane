package arcane.util;

#if macro
import haxe.macro.Expr;

using haxe.macro.Tools;
#end

class JsUtils {
	#if js
	public extern static inline function await<T>(p:js.lib.Promise<T>):T {
		return js.Syntax.code("await {0}", p);
	}
	#end

	@:noUsing public static macro function async(e:haxe.macro.Expr):haxe.macro.Expr {
		// function map(e:Expr) return e.map(e -> switch e {
		// 	case macro($e): map(e);
		// 	case macro $e: map(e);
		// });
		// e = map(e);
		switch e.expr {
			case EFunction(_, {
				args: args,
				ret: ret,
				expr: expr,
				params: params}):
				var t:ComplexType = TFunction(args.map(a -> a.type), macro:js.lib.Promise<$ret>);
				return macro(js.Syntax.code("(async {0})", $e) : $t);
			case _:
				return macro js.Syntax.code("(async () => {0})()", {$e;});
		}
	}
}
