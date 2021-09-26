package arcane.arrays;

abstract ArrayBuffer(haxe.io.Bytes) {
	public var byteLength(get, never):Int;

	inline function get_byteLength():Int {
		return this.length;
	}

	public inline function new(byteLength:Int) {
		this = haxe.io.Bytes.alloc(byteLength);
	}

	public inline function blit(pos:Int, src:ArrayBuffer, srcPos:Int, byteLength:Int) {
		this.blit(pos, cast src, srcPos, byteLength);
	}

	public inline function slice(begin:Int, end:Null<Int> = null) {
		if (end == null)
			end = this.length;
		if (begin < 0)
			begin = 0;
		if (end > this.length)
			end = this.length;
		var length = end - begin;
		if (begin < 0 || length <= 0) {
			return new ArrayBuffer(0);
		} else {
			var bytes = haxe.io.Bytes.alloc(length);
			bytes.blit(0, this, begin, length);
			return cast bytes;
		}
	}
}
