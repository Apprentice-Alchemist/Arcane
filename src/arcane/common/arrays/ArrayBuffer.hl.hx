package arcane.common.arrays;

@:allow(arcane)
class ArrayBuffer {
	public var byteLength(default, null):Int;

	var b:hl.Bytes;

	public static function fromBytes(b:hl.Bytes, l:Int) {
		var r:ArrayBuffer = untyped $new(ArrayBuffer);
		r.byteLength = l;
		r.b = b;
		return r;
	}

	public inline function new(byteLength:Int) {
		this.byteLength = byteLength;
		this.b = new hl.Bytes(byteLength);
	}

	public inline function slice(start:Int, ?end:Int) {
		if (end == null)
			end = byteLength;
		var length = end - start;
		var b = new ArrayBuffer(length);
		b.b.blit(0, this.b, start, length);
		return b;
	}
}
