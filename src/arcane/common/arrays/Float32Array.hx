package arcane.common.arrays;

private typedef Float32ArrayData = #if js js.lib.Float32Array #elseif hl hl.BytesAccess<hl.F32> #else Array<arcane.FastFloat> #end;

abstract Float32Array(Float32ArrayData) from Float32ArrayData {
	public inline function new(length:Int) {
		#if js
		this = new js.lib.Float32Array(length);
		#elseif hl
		this = new hl.Bytes(length * 4);
		#else
		this = [];
		this.resize(length);
		#end
	}

	@:op([]) public inline function get(i:Int):arcane.FastFloat {
		return this[i];
	}

	@:op([]) public inline function set(i:Int, v:arcane.FastFloat):FastFloat {
		return this[i] = v;
	}
}
