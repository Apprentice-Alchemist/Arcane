package arcane.common;

import haxe.Constraints;

@:generic
@:nullSafety(StrictThreaded)
class ObjectPool<T:Constructible<Void->Void>> {
	public var count(default, null):Int;

	private var pool:Array<T>;

	public function new() {
		pool = new Array();
		count = 0;
	}

	public function get():T {
		if (count == 0) {
			return new T();
		}
		return @:nullSafety(Off) (pool[--count] : T); // just in case they suddenly decide to type array.get as Null<T>
	}

	public function put(obj:T):Void {
		if (obj == null) // you never know
			return;
		var index = pool.indexOf(obj);
		if (index == -1 || index >= count) {
			pool[count++] = obj;
		}
	}

	public function preAllocate(objCount:Int):Void {
		while (objCount-- > 0) {
			pool[count++] = new T();
		}
	}
}
