package arcane.common;

@:eager private typedef Float = arcane.FastFloat;

@:notNull abstract Vector2(Array<Float>) from Array<Float> to Array<Float> {
	public extern inline function empty():Vector2 return [0, 0];

	public extern inline function new(arr:Array<Float>) this = arr;
}

@:notNull abstract Vector3(Array<Float>) from Array<Float> to Array<Float> {
	public extern inline function empty():Vector3 return [0, 0, 0];

	public extern inline function new(arr:Array<Float>) this = arr;
}

@:notNull abstract Vector4(Array<Float>) from Array<Float> to Array<Float> {
	public extern inline function empty():Vector4 return [0, 0, 0, 0];

	public extern inline function new(arr:Array<Float>) this = arr;
}

@:notNull
abstract Matrix3(Array<Float>) from Array<Float> to Array<Float> {
	public static extern inline function rotationX(alpha:Float) {
		var m = identity();
		var ca:Float = Math.cos(alpha);
		var sa:Float = Math.sin(alpha);
		m.set(1, 1, ca);
		m.set(1, 2, -sa);
		m.set(2, 1, sa);
		m.set(2, 2, ca);
		return m;
	}

	public static extern inline function rotationY(alpha:Float) {
		var m = identity();
		var ca:Float = Math.cos(alpha);
		var sa:Float = Math.sin(alpha);
		m.set(0, 0, ca);
		m.set(0, 2, sa);
		m.set(2, 0, -sa);
		m.set(2, 2, ca);
		return m;
	}

	public static extern inline function rotationZ(alpha:Float) {
		var m = identity();
		var ca:Float = Math.cos(alpha);
		var sa:Float = Math.sin(alpha);
		m.set(0, 0, ca);
		m.set(0, 1, -sa);
		m.set(1, 0, sa);
		m.set(1, 1, ca);
		return m;
	}

	public extern static inline function identity():Matrix3
		return [
			1, 0, 0,
			0, 1, 0,
			0, 0, 1,
		];

	public extern static inline function empty():Matrix3
		return [
			0, 0, 0,
			0, 0, 0,
			0, 0, 0,
		];

	private extern static inline var size:Int = 3;

	public extern inline function new(arr:Array<Float>) {
		this = arr;
	}

	public extern inline function get(x:Int, y:Int)
		return this[y * size + x];

	public extern inline function set(x:Int, y:Int, v:Float)
		this[y * size + x] = v;

	public extern inline function transpose():Matrix3 return null;

	public extern inline function trace():Float
		return get(0, 0) + get(1, 1) + get(2, 2);

	@:op(A + V) extern static inline function add(a:Matrix3, b:Matrix3):Matrix3
		return [for (i in 0...(size * size)) (a : Array<Float>) [i] + (b : Array<Float>)[i]];

	@:op(A + V) extern static inline function addv(a:Matrix3, b:Float):Matrix3
		return [for (i in (a : Array<Float>)) i + b];

	@:op(A - B) extern static inline function sub(a:Matrix3, b:Matrix3):Matrix3
		return [for (i in 0...(size * size)) (a : Array<Float>) [i] - (b : Array<Float>)[i]];

	@:op(A - B) extern static inline function subv(a:Matrix3, b:Float):Matrix3
		return [for (i in (a : Array<Float>)) i - b];

	@:op(A * B) extern static inline function mult(a:Matrix3, b:Matrix3):Matrix3
		return [
			for (x in 0...size)
				for (y in 0...size)
					a.get(x, y) * b.get(y, x) + a.get(x + 1, y + 1) * b.get(y + 1, x + 1) + a.get(x + 2, y + 2) * b.get(y + 2, x + 2)
		];

	@:op(A * B) extern static inline function multv(a:Matrix3, b:Float):Matrix3
		return [for (i in 0...(size * size)) a[i] * b];

	@:op(A * B) extern static inline function multvec(a:Matrix3, b:Vector3):Vector3
		return [
			b[0] * (a[0] + a[1] + a[2]),
			b[0] * (a[0 + 1] + a[1 + 1] + a[2 + 1]),
			b[0] * (a[0 + 2] + a[1 + 2] + a[2 + 2]),
		];

	public inline extern function clamp(min:Float, max:Float) {
		var ret = empty();
		for (i in 0...9) {
			var x = this[i];
			ret[i] = x < min ? min : (x > max ? max : x);
		}
		return ret;
	}

	#if kinc
	@:to extern inline function toKincMatrix():kinc.math.Matrix3 {
		var ret = new kinc.math.Matrix3();
		for (x in 0...size)
			for (y in 0...size)
				ret.set(x, y, get(x, y));
		return ret;
	}

	@:from extern static inline function fromKincMatrix(m:kinc.math.Matrix3) {
		var ret = empty();
		for (x in 0...size)
			for (y in 0...size)
				ret.set(x, y, m.get(x, y));
		return ret;
	}
	#end
}

@:notNull
abstract Matrix4(Array<Float>) from Array<Float> to Array<Float> {
	public extern static inline function scale(x:Float, y:Float, z:Float):Matrix4
		return [
			x, 0, 0, 0,
			0, y, 0, 0,
			0, 0, z, 0,
			0, 0, 0, 1
		];

	public extern static inline function rotation(yaw:Float, pitch:Float, roll:Float):Matrix4 {
		var sy = Math.sin(yaw);
		var cy = Math.cos(yaw);
		var sx = Math.sin(pitch);
		var cx = Math.cos(pitch);
		var sz = Math.sin(roll);
		var cz = Math.cos(roll);
		return [
			cx * cy, cx * sy * sz - sx * cz, cx * sy * cz + sx * sz, 0,
			sx * cy, sx * sy * sz + cx * cz, sx * sy * cz - cx * sz, 0,
			    -sy,                cy * sz,                cy * cz, 0,
			      0,                      0,                      0, 1
		];
	}

	public extern static inline function identity():Matrix4
		return [
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1
		];

	public extern static inline function empty():Matrix4
		return [
			0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0
		];

	private static inline var size:Int = 4;

	public extern inline function new(arr:Array<Float>) {
		this = arr;
	}

	public extern inline function get(x:Int, y:Int)
		return this[y * size + x];

	public extern inline function set(x:Int, y:Int, v:Float)
		this[y * size + x] = v;

	public extern inline function transpose():Matrix4 return null;

	public extern inline function trace():Float
		return get(0, 0) + get(1, 1) + get(2, 2) + get(3, 3);

	@:op(A + V) extern static inline function add(a:Matrix4, b:Matrix4):Matrix4
		return [for (i in 0...(size * size)) (a : Array<Float>) [i] + (b : Array<Float>)[i]];

	@:op(A + V) extern static inline function addv(a:Matrix4, b:Float):Matrix4
		return [for (i in (a : Array<Float>)) i + b];

	@:op(A - B) extern static inline function sub(a:Matrix4, b:Matrix4):Matrix4
		return [for (i in 0...(size * size)) (a : Array<Float>) [i] - (b : Array<Float>)[i]];

	@:op(A - B) extern static inline function subv(a:Matrix4, b:Float):Matrix4
		return [for (i in (a : Array<Float>)) i - b];

	@:op(A * B) extern static inline function mult(a_:Matrix4, b_:Matrix4):Matrix4 {
		inline function a(x:Int, y:Int) return a_.get(x, y);
		inline function b(x:Int, y:Int) return b_.get(x, y);
		return [a(0, 0) * b(0, 0) + a(1, 0) * b(0, 1) + a(2, 0) * b(0, 2) + a(3, 0) * b(0, 3),
			a(0, 0) * b(1, 0)
			+ a(1, 0) * b(1, 1)
			+ a(2, 0) * b(1, 2)
			+ a(3, 0) * b(1, 3),
			a(0, 0) * b(2, 0)
			+ a(1, 0) * b(2, 1)
			+ a(2, 0) * b(2, 2)
			+ a(3, 0) * b(2, 3),
			a(0, 0) * b(3, 0)
			+ a(1, 0) * b(3, 1)
			+ a(2, 0) * b(3, 2)
			+ a(3, 0) * b(3, 3),
			a(0, 1) * b(0, 0)
			+ a(1, 1) * b(0, 1)
			+ a(2, 1) * b(0, 2)
			+ a(3, 1) * b(0, 3),
			a(0, 1) * b(1, 0)
			+ a(1, 1) * b(1, 1)
			+ a(2, 1) * b(1, 2)
			+ a(3, 1) * b(1, 3),
			a(0, 1) * b(2, 0)
			+ a(1, 1) * b(2, 1)
			+ a(2, 1) * b(2, 2)
			+ a(3, 1) * b(2, 3),
			a(0, 1) * b(3, 0)
			+ a(1, 1) * b(3, 1)
			+ a(2, 1) * b(3, 2)
			+ a(3, 1) * b(3, 3),
			a(0, 2) * b(0, 0)
			+ a(1, 2) * b(0, 1)
			+ a(2, 2) * b(0, 2)
			+ a(3, 2) * b(0, 3),
			a(0, 2) * b(1, 0)
			+ a(1, 2) * b(1, 1)
			+ a(2, 2) * b(1, 2)
			+ a(3, 2) * b(1, 3),
			a(0, 2) * b(2, 0)
			+ a(1, 2) * b(2, 1)
			+ a(2, 2) * b(2, 2)
			+ a(3, 2) * b(2, 3),
			a(0, 2) * b(3, 0)
			+ a(1, 2) * b(3, 1)
			+ a(2, 2) * b(3, 2)
			+ a(3, 2) * b(3, 3),
			a(0, 3) * b(0, 0)
			+ a(1, 3) * b(0, 1)
			+ a(2, 3) * b(0, 2)
			+ a(3, 3) * b(0, 3),
			a(0, 3) * b(1, 0)
			+ a(1, 3) * b(1, 1)
			+ a(2, 3) * b(1, 2)
			+ a(3, 3) * b(1, 3),
			a(0, 3) * b(2, 0)
			+ a(1, 3) * b(2, 1)
			+ a(2, 3) * b(2, 2)
			+ a(3, 3) * b(2, 3),
			a(0, 3) * b(3, 0)
			+ a(1, 3) * b(3, 1)
			+ a(2, 3) * b(3, 2)
			+ a(3, 3) * b(3, 3)];
	}

	@:op(A * B) extern static inline function multv(a:Matrix4, b:Float):Matrix4
		return [for (i in 0...(size * size)) a[i] * b];

	@:op(A * B) extern static inline function multvec(a:Matrix4, b:Vector4):Vector4
		return [
			b[0] * (a[0] + a[1] + a[2] + a[3]),
			b[0] * (a[0 + 1] + a[1 + 1] + a[2 + 1] + a[3 + 1]),
			b[0] * (a[0 + 2] + a[1 + 2] + a[2 + 2] + a[3 + 2]),
			b[0] * (a[0 + 3] + a[1 + 3] + a[2 + 3] + a[3 + 3])
		];

	public inline extern function clamp(min:Float, max:Float) {
		var ret = empty();
		for (i in 0...9) {
			var x = this[i];
			ret[i] = x < min ? min : (x > max ? max : x);
		}
		return ret;
	}

	#if kinc
	@:to extern inline function toKincMatrix():kinc.math.Matrix4 {
		var ret = new kinc.math.Matrix4();
		for (x in 0...size)
			for (y in 0...size)
				ret.set(x, y, get(x, y));
		return ret;
	}

	@:from extern static inline function fromKincMatrix(m:kinc.math.Matrix4) {
		var ret = empty();
		for (x in 0...size)
			for (y in 0...size)
				ret.set(x, y, m.get(x, y));
		return ret;
	}
	#end
}
