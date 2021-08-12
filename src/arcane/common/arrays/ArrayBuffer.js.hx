package arcane.common.arrays;

@:forward(byteLength, slice)
abstract ArrayBuffer(js.lib.ArrayBuffer) {
	public inline function new(byteLength) {
		this = new js.lib.ArrayBuffer(byteLength);
	}
}