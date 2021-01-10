package arcane.common;

/**
 * ARGB Color
 */
abstract Color(Int) from Int to Int {
	public var r(get, set):Int;
	public var g(get, set):Int;
	public var b(get, set):Int;
	public var a(get, set):Int;

	public inline function new(i:Int) {
		this = i;
	}

	private inline function get_a():Int
		return this >> 24 & 0xff;

	private inline function get_r():Int
		return this >> 16 & 0xff;

	private inline function get_g():Int
		return this >> 8 & 0xff;

	private inline function get_b():Int
		return this & 0xff;

	private inline function set_a(v:Int):Int {
		this = ((this & 0x00ffffff) | ((v & 0xff) << 24));
		return v & 0xff;
	}

	private inline function set_r(v:Int):Int {
		this = (this & 0xff00ffff) | ((v & 0xff) << 16);
		return v & 0xff;
	}

	private inline function set_g(v:Int):Int {
		this = (this & 0xffff00ff) | ((v & 0xff) << 8);
		return v & 0xff;
	}

	private inline function set_b(v:Int):Int {
		this = (this & 0xffffff00) | (v & 0xff);
		return v & 0xff;
	}

	public inline function getRGB():Int
		return this & 0x00ffffff;

	private inline function toString():String
		return "0x" + StringTools.hex(a, 2) + StringTools.hex(r, 2) + StringTools.hex(g, 2) + StringTools.hex(b, 2);
}

function main() @:privateAccess {
	var col:Color = 0x00ff0000;
	var a = 0xff;
	trace(StringTools.hex(0x00ff | (0xff << 8)));
	trace(col.toString());
	trace(col.r);
	col.a = a;
	trace(col.toString());
	trace(col.a);
}
