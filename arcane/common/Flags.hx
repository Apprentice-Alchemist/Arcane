package arcane.common;

abstract Flags(Int) from Int to Int {
	public inline function new()
		this = 0;
	public inline function addFlag(x:Int) {
		// this = this OR x
		this = this | x;
	}

	public inline function hasFlag(x:Int) {
		// this AND x EQUALS X
		return this & x == x;
	}

	public inline function removeFlag(x:Int) {
		// this = this AND NOT x
		this = this & ~x;
	}
}