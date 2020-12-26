package arcane;

class Utils {
	public static function parseInt(i:Null<String>):Int {
		if (i == null) return 0;
		var tmp = Std.parseInt(i);
		if (tmp == null) return 0;
		return tmp;
	}

	public static function parseFloat(f:Null<String>):Float {
		if (f == null) return 0.0;
		var tmp = Std.parseFloat(f);
		if (!Math.isFinite(tmp)) return 0.0;
		return tmp;
	}

	public static function int(f:Null<Float>):Int {
		if (f == null || !Math.isFinite(f)) return 0;
		return Std.int(f);
	}
	
	public static extern inline function assert(b:Bool,msg:String)
		if(!b) throw 'assert : $msg';

	// #if !macro
	// public static macro function assert(expr:ExprOf<Bool>):ExprOf<Bool> {
	// 	switch expr.expr {
	// 		case EConst(CIdent("true")):
	// 			return macro @:pos(${haxe.macro.Context.currentPos()}) true;
	// 		case EConst(CIdent("false")):
	// 			return macro @:pos(${haxe.macro.Context.currentPos()}) throw "assert";
	// 		default: 
	// 	}
	// 	return macro @:pos(${haxe.macro.Context.currentPos()}) if ($expr) true else throw "assert";
	// }
	// #end
}