package arcane.common.arrays;

import hl.BytesAccess;

abstract Float32Array(ArrayBuffer) {
	public var length(get, never):Int;

	inline function get_length():Int {
		return cast this.byteLength / 4;
	}

	public inline function new(length:Int) {
		this = new ArrayBuffer(length * 4);
	}

	@:op([]) public inline function get(i:Int):arcane.FastFloat {
		return (this.b:hl.BytesAccess<hl.F32>)[i];
	}

	@:op([]) public inline function set(i:Int, v:arcane.FastFloat):FastFloat {
		return (this.b : hl.BytesAccess<hl.F32>)[i] = v;
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