package arcane.common.arrays;

abstract Int32Array(ArrayBuffer) to ArrayBuffer {
	public var length(get, never):Int;

	inline function get_length():Int {
		return cast this.byteLength / 4;
	}

	public inline function new(length:Int) {
		this = new ArrayBuffer(length * 4);
	}

	@:op([]) public inline function get(i:Int):Int {
		return (cast this : haxe.io.Bytes).getInt32(i * 4);
	}

	@:op([]) public inline function set(i:Int, v:Int):Int {
		(cast this : haxe.io.Bytes).setInt32(i * 4, v);
		return v;
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
}
