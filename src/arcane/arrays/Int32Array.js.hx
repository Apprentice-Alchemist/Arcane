package arcane.arrays;

@:forward(length)
abstract Int32Array(js.lib.Int32Array) from js.lib.Int32Array {
	public inline function new(length:Int) {
		this = new js.lib.Int32Array(length);
	}

	@:op([]) inline function get(i:Int):Int {
		return this[i];
	}

	@:op([]) inline function set(i:Int, v:Int):Int {
		return this[i] = v;
	}

	/**
	 * Get a Int32Array from an Array<Int>. Copy occurs.
	 * @param array 
	 * @return Int32Array
	 */
	public static function fromArray(array:Array<Int>):Int32Array {
		final arr = new Int32Array(array.length);
		for (i => element in array)
			arr[i] = element;
		return arr;
	}

	@:to inline function toArrayBuffer() return this.buffer;

	@:to inline function toAArrayBuffer():arcane.arrays.ArrayBuffer return this.buffer;

	@:from static inline function fromArrayBuffer(buffer:ArrayBuffer):Int32Array return new js.lib.Int32Array(buffer);
}
