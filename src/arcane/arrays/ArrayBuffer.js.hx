package arcane.arrays;

@:forward(byteLength, slice)
abstract ArrayBuffer(js.lib.ArrayBuffer) from js.lib.ArrayBuffer to js.lib.ArrayBuffer {
	public inline function new(byteLength) {
		this = new js.lib.ArrayBuffer(byteLength);
	}

	public inline function blit(pos:Int, src:ArrayBuffer, srcPos:Int, byteLength:Int) {
		new js.lib.Uint8Array(this).set(new js.lib.Uint8Array(src, srcPos, byteLength), pos);
	}
}
