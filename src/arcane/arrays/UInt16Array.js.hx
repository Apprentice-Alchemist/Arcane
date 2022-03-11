package arcane.arrays;

@:forward(length)
abstract UInt16Array(js.lib.UInt16Array) from js.lib.UInt16Array {
	public inline function new(length:Int) {
		this = new js.lib.UInt16Array(length);
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
	public static function fromArray(array:Array<Int>):UInt16Array {
		final arr = new UInt16Array(array.length);
		for (i => element in array)
			arr[i] = element;
		return arr;
	}

	@:to inline function toArrayBuffer() return this.buffer;

	@:from static inline function fromArrayBuffer(buffer:ArrayBuffer):UInt16Array return new js.lib.UInt16Array(buffer);
}
