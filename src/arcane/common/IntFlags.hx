package arcane.common;

abstract IntFlags(Int) from Int to Int {
	public inline function new()
		this = 0;

	public inline function add(x:Int):Void {
		// this = this OR x
		this |= x;
	}

	@:pure public inline function has(x:Int):Bool {
		// this AND x EQUALS X
		return this & x == x;
	}

	public inline function remove(x:Int):Void {
		// this = this AND NOT x
		this = this & ~x;
	}
}
