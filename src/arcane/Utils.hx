package arcane;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.Tools;
#end

@:nullSafety(Strict)
class Utils {
	/**
	 * Converts a String to an Int.
	 * If x is null or does not represent a valid integer, the result is 0.
	 */
	@:noUsing public static function parseInt(x:Null<String>):Int {
		if (x == null)
			return 0;
		var tmp = Std.parseInt(x);
		if (tmp == null)
			return 0;
		return tmp;
	}

	/**
	 * Converts a String to a Float.
	 * If x is null or does not represent a valid float, the result is 0.0.
	 */
	@:noUsing public static function parseFloat(x:Null<String>):Float {
		if (x == null)
			return 0.0;
		var tmp = Std.parseFloat(x);
		if (!Math.isFinite(tmp))
			return 0.0;
		return tmp;
	}

	/**
	 * Converts a Float to an Int, rounded towards 0.
	 * If f is null, or `Math.isFinite(f)` doesn't hold, the result is 0.
	 */
	@:noUsing public static function int(f:Null<Float>):Int {
		if (f == null || !Math.isFinite(f))
			return 0;
		return Std.int(f);
	}

	/**
	 * Assertion helper.
	 */
	@:noUsing public static macro function assert(b:haxe.macro.Expr.ExprOf<Bool>, msg:String = "assertion failed : "):haxe.macro.Expr.ExprOf<Bool> {
		return macro @:pos(b.pos) if (!$b) {
			throw $v{msg} + " (" + $v{b.toString()} + ")";
		} else {
			true;
		}
	}

	/**
	 * Uses the appropriate ci assert helper, or falls back to `arcane.Utils.assert`.
	 * @param b 
	 * @param msg 
	 */
	@:noUsing public static macro function ciAssert(b:haxe.macro.Expr.ExprOf<Bool>, msg:String = "assertion failed :"):haxe.macro.Expr.ExprOf<Bool> {
		if (Context.defined("ci") && Context.defined("utest")) {
			return macro @:pos(b.pos) utest.Assert.isTrue($b, $v{msg} + " (" + $v{b.toString()} + ")");
		} else {
			return macro @:pos(b.pos) arcane.Utils.assert($b, $v{msg});
		}
	}

	public static inline function sure<T>(v:Null<T>):T {
		if (v == null)
			throw "did not expect a null value";
		else
			return (v : T);
	}

	public static inline function or<T>(v:Null<T>, other:T):T {
		return if (v == null) other else (v : T);
	}
}
