package arcane.arrays;

abstract Float32Array(ArrayBuffer) from ArrayBuffer to ArrayBuffer {
	public var length(get, never):Int;

	inline function get_length():Int {
		return this.byteLength >> 4;
	}

	public inline function new(length:Int) {
		this = new ArrayBuffer(length * 4);
	}

	@:op([]) public inline function get(i:Int):arcane.FastFloat {
		return (cast this : haxe.io.Bytes).getFloat(i * 4);
	}

	@:op([]) public inline function set(i:Int, v:arcane.FastFloat):FastFloat {
		(cast this : haxe.io.Bytes).setFloat(i * 4, v);
		return v;
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
}
