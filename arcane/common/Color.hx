package arcane.common;
/**
 * RGBA Color
 */
abstract Color(Int) from Int to Int {
	public var r(get, never):Int;
	public var g(get, never):Int;
	public var b(get, never):Int;
	public var a(get, never):Int;

	public inline function new(i:Int) {
        this = i;
	}

	private inline function get_r():Int
		return this >> 24 & 0xff;

	private inline function get_g():Int
		return this >> 16 & 0xff;

	private inline function get_b():Int
		return this >> 8 & 0xff;

	private inline function get_a():Int
		return this & 0xff;

	// private inline function set_r(v:Int):Int
	//     return this >> 24 & 0xff;
	// private inline function set_g(v:Int):Int
	//     return this >> 16 & 0xff;
	// private inline function set_b(v:Int):Int
	//     return this >> 8 & 0xff;
	// private inline function set_a(v:Int):Int
	//     return this & 0xff;

	private inline function toString():String
		return StringTools.hex(this, 8);
}
