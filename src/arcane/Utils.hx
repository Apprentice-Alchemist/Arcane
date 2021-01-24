package arcane;

@:nullSafety
class Utils {
	public static function parseInt(i:Null<String>):Int {
		if(i == null)
			return 0;
		var tmp = Std.parseInt(i);
		if(tmp == null)
			return 0;
		return tmp;
	}

	public static function parseFloat(f:Null<String>):Float {
		if(f == null)
			return 0.0;
		var tmp = Std.parseFloat(f);
		if(!Math.isFinite(tmp))
			return 0.0;
		return tmp;
	}

	public static function int(f:Null<Float>):Int {
		if(f == null || !Math.isFinite(f))
			return 0;
		return Std.int(f);
	}

	public static inline function assert(b:Bool, msg:String = "assert") {
		#if (!arcane_no_assert)
		if(!b)
			throw msg;
		#end
	}
}
