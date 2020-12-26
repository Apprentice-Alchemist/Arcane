package arcane.util;


class ThreadUtil {
	#if target.threaded
	public static function megaPop<T>(d:sys.thread.Deque<T>):Array<T> {
		var ret:Array<T> = [];
		var val:T = d.pop(false);
		while (val != null) {
			ret.push(val);
			val = d.pop(false);
		}
		return ret;
	}
	#end
}
