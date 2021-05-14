package arcane.util;

enum abstract Color(Int) {
	var None = 0;
	var Black = 30;
	var Red = 31;
	var Green = 32;
	var Yellow = 33;
	var Blue = 34;
	var Purple = 35;
	var Cyan = 36;
	var White = 37;
}

enum abstract Style(Int) {
	var Normal = 0;
	var Bold = 1;
	var Underline = 4;
}

class Log {
	public static var is_verbose:Bool = false;
	public static var warning_disabled:Bool = false;

	public static inline function setColor(color:Color, style:Style = Style.Normal):String {
		#if arcane_log_color
		var id = (color == Color.None) ? "" : ';$color';
		return "\033[" + 0 + id + "m";
		#else
		return "";
		#end
	}

	public static function println(msg:String):Void {
		#if sys
		Sys.println(msg);
		#elseif js
		js.Browser.console.log(msg);
		#end
	}

	public static function info(msg:String):Void {
		if (is_verbose)
			println(msg);
	}

	public static function warn(msg:String):Void {
		if (!warning_disabled)
			#if js
			js.Browser.console.warn(msg);
			#else
			println(setColor(Yellow) + msg + setColor(None));
			#end
	}

	public static function error(msg:String):Void {
		#if js
		js.Browser.console.error(msg);
		#else
		var text = setColor(Red) + msg + setColor(None);
		println(text);
		#end
	}
}
