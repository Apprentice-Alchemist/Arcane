package arcane.common;

import haxe.Constraints;

private typedef Destroyable = {
	function destroy():Void;
}

@:generic
@:nullSafety
class ObjectPool<T:Constructible<Void->Void> & Destroyable> {
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
        return pool[--count];
	}

	public function put(obj:T):Void {
        if(obj == null) return;
		var index = pool.indexOf(obj);
		if (index == -1 || index >= count) {
			obj.destroy();
			pool[count++] = obj;
		}
	}

	public function preAllocate(objCount:Int):Void {
		while (objCount-- > 0) {
			pool[count++] = new T();
		}
	}
}
