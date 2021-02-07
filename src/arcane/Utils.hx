package arcane;

#if macro
import haxe.macro.Context;

using haxe.macro.Tools;
#end

@:nullSafety
class Utils {
	/**
	 * Converts a String to an Int.
	 * If x is null or does not represent a valid integer, the result is 0.
	 */
	public static function parseInt(x:Null<String>):Int {
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
	public static function parseFloat(x:Null<String>):Float {
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
	public static function int(f:Null<Float>):Int {
		if (f == null || !Math.isFinite(f))
			return 0;
		return Std.int(f);
	}

	/**
	 * Assertion helper.
	 * Enable with `-D arcane_assert`, disable with `-D arcane_no_assert`.
	 * Always enable when compiling with `--debug`.
	 */
	public static macro function assert(b, msg:String = "assert") {
		if ((Context.defined("debug") || Context.defined("arcane_assert")) && !Context.defined("arcane_no_assert"))
			return macro if (!$b)
				throw $v{msg} + " " + $v{b.toString()} + " != true"
			else
				$b;
		else
			return macro $b;
	}
}
