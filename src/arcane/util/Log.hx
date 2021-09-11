package arcane.util;

enum abstract LogColor(Int) {
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

enum abstract LogStyle(Int) {
	var Normal = 0;
	var Bold = 1;
	var Underline = 4;
}

class Log {
	public static var WARN = #if (log_no_warning) false #else true #end;
	public static var VERBOSE = #if (log_verbose || verbose) true #else false #end;
	// in the js console positions will show up anyway
	public static var LOG_POSITION = #if (log_position || (js && (!debug && !source_maps))) true #else false #end;

	static inline function format(message:Dynamic, pos:haxe.PosInfos) {
		return #if log_position haxe.Log.formatOutput(message, pos) #else Std.string(message) #end;
	}

	public static inline function setColor(color:LogColor, style:LogStyle = LogStyle.Normal):String {
		#if arcane_log_color
		var id = (color == Color.None) ? "" : ';$color';
		return "\033[" + 0 + id + "m";
		#else
		return "";
		#end
	}

	public static inline function println(msg:Dynamic, ?pos:haxe.PosInfos):Void {
		final msg = format(msg, pos);
		#if sys
		Sys.println(msg);
		#elseif js
		js.Browser.console.log(msg);
		#end
	}

	public static inline function info(msg:Dynamic, ?pos:haxe.PosInfos):Void {
		if (VERBOSE)
			println(msg, pos);
	}

	public static inline function warn(msg:Dynamic, ?pos:haxe.PosInfos):Void {
		final msg = format(msg, pos);
		if (WARN)
			#if js
			js.Browser.console.warn(msg);
			#else
			println(setColor(Yellow) + msg + setColor(None));
			#end
	}

	public static inline function error(msg:Dynamic, ?pos:haxe.PosInfos):Void {
		final msg = format(msg, pos);
		#if js
		js.Browser.console.error(msg);
		#else
		var text = setColor(Red) + msg + setColor(None);
		println(text);
		#end
	}
}
