package arcane.util;

class Log {
	public static function log(msg:Dynamic, ?pos:haxe.PosInfos) {
		haxe.Log.trace(msg, pos);
	}

	public static function error(msg:Dynamic, ?pos:haxe.PosInfos) {
		haxe.Log.trace('Error : $msg at ${formatPos(pos)}', null);
	}

	public static function warn(msg:Dynamic, ?pos:haxe.PosInfos) {
		haxe.Log.trace('Warning : $msg at ${formatPos(pos)}', null);
	}

	static function formatPos(infos:haxe.PosInfos):String {
		var str = "";
		var pstr = infos.fileName + ":" + infos.lineNumber;
		if (infos.customParams != null)
			for (v in infos.customParams)
				str += ", " + Std.string(v);
		return pstr;
	}
}
