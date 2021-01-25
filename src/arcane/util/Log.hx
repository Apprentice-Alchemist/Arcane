package arcane.util;

class Log {
	public static function log(msg:Dynamic, ?pos:haxe.PosInfos) {
		haxe.Log.trace(Std.string(msg), pos);
	}

	public static function error(msg:Dynamic, ?pos:haxe.PosInfos) {
		haxe.Log.trace('Error : ${Std.string(msg)} at ${formatPos(pos)}', null);
	}

	public static function warn(msg:Dynamic, ?pos:haxe.PosInfos) {
		haxe.Log.trace('Warning : ${Std.string(msg)} at ${formatPos(pos)}', null);
	}

	public static function formatPos(infos:haxe.PosInfos):String {
		return infos.fileName + ":" + infos.lineNumber;
	}
}
