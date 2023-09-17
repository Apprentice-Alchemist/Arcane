using Test;

class Test {
	static function main() {
		trace("Haxe is great!");
		trace("foo\nbar".lines().filter(s -> s != "foo").collect());
	}

	static function lines(s:String):Iterator<String> {
		return s.split("\n").iterator(); // TODO: bad! should be a lazy iter!
	}

	static function filter<T>(i:Iterator<T>, fn:T->Bool):Iterator<T> {
		return new FilterIter(i, fn);
	}

	static function collect<T>(iter:Iterator<T>):Array<T> {
		return [for (i in iter) i];
	}
}

class FilterIter<T> {
	var inner:Iterator<T>;
	var fn:T->Bool;

	var _hasNext:Bool = false;
	var _next:T = null;

	public inline function new(i:Iterator<T>, fn:T->Bool) {
		inner = i;
		this.fn = fn;
		while (inner.hasNext()) {
			var n = inner.next();
			if (fn(n)) {
				_hasNext = true;
				_next = n;
				break;
			}
		}
	}

	public inline function hasNext():Bool {
		return _hasNext;
	}

	public inline function next():Null<T> {
		var ret = if (_hasNext) _next else null;
		_hasNext = false;
		_next = null;
		while (inner.hasNext()) {
			var n = inner.next();
			if (fn(n)) {
				_hasNext = true;
				_next = n;
				break;
			}
		}
		return ret;
	}
}
