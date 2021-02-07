package arcane.util;

class Log {
	public static var is_verbose:Bool = false;
	public static var warning_disabled:Bool = false;

	public static function print(msg:String):Void #if sys Sys.print(msg); #elseif js if (untyped console)
		(untyped console : js.html.ConsoleInstance).log(msg); #else {} #end

	public static function println(msg:String):Void #if sys Sys.println(msg); #elseif js if (untyped console)
		(untyped console : js.html.ConsoleInstance).log(msg); #else {} #end

	public static function info(msg:String):Void {
		if (is_verbose)
			println(msg);
	}

	public static function warning(msg:String):Void {
		if (!warning_disabled)
			println("Warning : " + msg);
	}

	public static function error(msg:String, fatal = false):Void {
		if (fatal) {
			println("Fatal Error : " + msg);
			#if sys
			println("Exiting...");
			Sys.exit(1);
			#end
		} else {
			println("Error : " + msg);
		}
	}
}
