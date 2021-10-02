package arcane.arrays;

@:forward(length)
abstract Float32Array(js.lib.Float32Array) from js.lib.Float32Array to js.lib.Float32Array {
	public inline function new(length:Int) {
		this = new js.lib.Float32Array(length);
	}

	@:op([]) inline function get(i:Int):arcane.FastFloat {
		return this[i];
	}

	@:op([]) inline function set(i:Int, v:arcane.FastFloat):FastFloat {
		return this[i] = v;
	}

	/**
	 * Get a Float32Array from an Array<Float>. Copy occurs.
	 * @param array 
	 * @return Float32Array
	 */
	public static function fromArray(array:Array<Float>):Float32Array {
		final arr = new Float32Array(array.length);
		for (i => element in array)
			arr[i] = element;
		return arr;
	}

	@:to inline function toArrayBuffer() return this.buffer;

	@:from static inline function fromArrayBuffer(buffer:ArrayBuffer):Float32Array return new js.lib.Float32Array(buffer);
}
