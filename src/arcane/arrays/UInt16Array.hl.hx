package arcane.arrays;

import hl.BytesAccess;

abstract UInt16Array(ArrayBuffer) from ArrayBuffer to ArrayBuffer {
	public var length(get, never):Int;

	inline function get_length():Int {
		return this.byteLength >> 1;
	}

	public inline function new(length:Int) {
		this = new ArrayBuffer(length * 2);
	}

	@:op([]) public inline function get(i:Int):Int {
		return (this.b : hl.BytesAccess<hl.UI16>)[i];
	}

	@:op([]) public inline function set(i:Int, v:Int):Int {
		return (this.b : hl.BytesAccess<hl.UI16>)[i] = v;
	}

	/**
	 * Get a UInt16Array from an Array<Float>. Copy occurs.
	 * @param array 
	 * @return UInt16Array
	 */
	public static function fromArray(array:Array<Int>):UInt16Array {
		final arr = new UInt16Array(array.length);
		for (i => element in array)
			arr[i] = element;
		return arr;
	}
}
