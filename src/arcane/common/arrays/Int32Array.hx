package arcane.common.arrays;

private typedef Int32ArrayData = #if js js.lib.Int32Array #elseif hl hl.BytesAccess<Int> #else Array<Int> #end;

abstract Int32Array(Int32ArrayData) from Int32ArrayData {
	public inline function new(length:Int) {
		#if js
		this = new js.lib.Int32Array(length);
		#elseif hl
		this = new hl.Bytes(length * 4);
		#else
        this = [];
        this.resize(length);
        #end
	}

	@:op([]) public inline function get(i:Int):Int {
		return this[i];
	}

	@:op([]) public inline function set(i:Int, v:Int):Int {
		return this[i] = v;
	}
}
