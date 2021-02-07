package arcane.common;

// @:eager private typedef Float = arcane.FastFloat;

@:forward
@:forward.new
abstract Vector3(Vec3Internal) {
	public inline static function empty():Vector3 {
		return new Vector3(0, 0, 0);
	}

	public inline function dot(b:Vector3):Float {
		return this.x * b.x + this.y * b.y + this.z * b.z;
	}
}

@:forward
@:forward.new
abstract Vector4(Vec4Internal) {
	public inline static function empty():Vector4 {
		return new Vector4(0, 0, 0, 0);
	}

	public inline function dot(b:Vector4):Float {
		return this.x * b.x + this.y * b.y + this.z * b.z + this.w * b.w;
	}
}

@:forward
@:forward.new
abstract Matrix3(Mat3Internal) {
	public static inline function rotationX(alpha:Float):Matrix3 {
		var m = identity();
		var ca:Float = Math.cos(alpha);
		var sa:Float = Math.sin(alpha);
		m._22 = ca;
		m._23 = -sa;
		m._32 = sa;
		m._33 = ca;
		return m;
	}

	public static inline function rotationY(alpha:Float):Matrix3 {
		var m = identity();
		var ca:Float = Math.cos(alpha);
		var sa:Float = Math.sin(alpha);
		m._11 = ca;
		m._13 = sa;
		m._31 = -sa;
		m._33 = ca;
		return m;
	}

	public static inline function rotationZ(alpha:Float):Matrix3 {
		var m = identity();
		var ca:Float = Math.cos(alpha);
		var sa:Float = Math.sin(alpha);
		m._11 = ca;
		m._12 = -sa;
		m._21 = sa;
		m._22 = ca;
		return m;
	}

	public inline static function identity():Matrix3 {
		return new Matrix3(
			1, 0, 0,
			0, 1, 0,
			0, 0, 1
		);
	}

	public inline static function empty():Matrix3 {
		return new Matrix3(
			0, 0, 0,
			0, 0, 0,
			0, 0, 0
		);
	}

	public inline function transpose():Matrix3 {
		return new Matrix3(
			this._11, this._21, this._31,
			this._12, this._22, this._32,
			this._13, this._23, this._33
		);
	}

	public inline function trace():Float {
		return this._11 + this._22 + this._33;
	}

	@:op(A + V) inline static function add(a:Matrix3, b:Matrix3):Matrix3 {
		return new Matrix3(
			a._11 + b._11, a._12 + b._12, a._13 + b._13,
			a._21 + b._21, a._22 + b._22, a._23 + b._23,
			a._31 + b._31, a._32 + b._32, a._33 + b._33
		);
	}

	@:commutative
	@:op(A + V) inline static function addf(a:Matrix3, b:Float):Matrix3 {
		return new Matrix3(
			a._11 + b, a._12 + b, a._13 + b,
			a._21 + b, a._22 + b, a._23 + b,
			a._31 + b, a._32 + b, a._33 + b
		);
	}

	@:op(A - B) inline static function sub(a:Matrix3, b:Matrix3):Matrix3 {
		return new Matrix3(
			a._11 - b._11, a._12 - b._12, a._13 - b._13,
			a._21 - b._21, a._22 - b._22, a._23 - b._23,
			a._31 - b._31, a._32 - b._32, a._33 - b._33
		);
	}

	@:op(A - B) inline static function subf(a:Matrix3, b:Float):Matrix3 {
		return new Matrix3(
			a._11 - b, a._12 - b, a._13 - b,
			a._21 - b, a._22 - b, a._23 - b,
			a._31 - b, a._32 - b, a._33 - b
		);
	}

	@:op(A - B) inline static function fsub(a:Float, b:Matrix3):Matrix3 {
		return new Matrix3(
			a - b._11, a - b._12, a - b._13,
			a - b._21, a - b._22, a - b._23,
			a - b._31, a - b._32, a - b._33
		);
	}

	@:op(A * B) inline static function mult(a:Matrix3, b:Matrix3):Matrix3 {
		var a1 = new Vector3(a._11, a._12, a._13);
		var a2 = new Vector3(a._21, a._22, a._23);
		var a3 = new Vector3(a._31, a._32, a._33);

		var b1 = new Vector3(b._11, b._21, b._31);
		var b2 = new Vector3(b._12, b._22, b._32);
		var b3 = new Vector3(b._13, b._23, b._33);

		return new Matrix3(
			a1.dot(b1), a1.dot(b2), a1.dot(b3),
			a2.dot(b1), a2.dot(b2), a2.dot(b3),
			a3.dot(b1), a3.dot(b2), a3.dot(b3)
		);
	}

	@:commutative
	@:op(A * B) inline static function multf(a:Matrix3, b:Float):Matrix3 {
		return new Matrix3(
			a._11 * b, a._12 * b, a._13 * b,
			a._21 * b, a._22 * b, a._23 * b,
			a._31 * b, a._32 * b, a._33 * b
		);
	}

	@:op(A * B) inline static function multvec(a:Matrix3, b:Vector3):Vector3 {
		var a1 = new Vector3(a._11, a._12, a._13);
		var a2 = new Vector3(a._21, a._22, a._23);
		var a3 = new Vector3(a._31, a._32, a._33);

		return new Vector3(a1.dot(b), a2.dot(b), a3.dot(b));
	}
}

@:forward.new
@:forward
@:pure
abstract Matrix4(Mat4Internal) {
	public static inline function scale(x:Float, y:Float, z:Float):Matrix4 {
		return new Matrix4(
			x, 0, 0, 0,
			0, y, 0, 0,
			0, 0, z, 0,
			0, 0, 0, 1
		);
	}

	public static inline function rotation(yaw:Float, pitch:Float, roll:Float):Matrix4 {
		var sy = Math.sin(yaw);
		var cy = Math.cos(yaw);
		var sx = Math.sin(pitch);
		var cx = Math.cos(pitch);
		var sz = Math.sin(roll);
		var cz = Math.cos(roll);
		return new Matrix4(
			cx * cy, cx * sy * sz - sx * cz, cx * sy * cz + sx * sz, 0,
			sx * cy, sx * sy * sz + cx * cz, sx * sy * cz - cx * sz, 0,
			-sy, cy * sz, cy * cz, 0,
			0, 0, 0, 1
		);
	}

	public inline static function identity():Matrix4 {
		return new Matrix4(
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1
		);
	}

	public inline static function empty():Matrix4 {
		return new Matrix4(
			0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0
		);
	}

	public inline static function translation(x:Float, y:Float, z:Float):Matrix4 {
		return new Matrix4(
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			x, y, z, 1
		);
	}

	public inline static function orthogonalProjection(left:Float, right:Float, bottom:Float, top:Float, zn:Float, zf:Float):Matrix4 {
		var tx:Float = -(right + left) / (right - left);
		var ty:Float = -(top + bottom) / (top - bottom);
		var tz:Float = -(zf + zn) / (zf - zn);
		return new Matrix4(
			2 / (right - left), 0, 0, tx,
			0, 2.0 / (top - bottom), 0, ty,
			0, 0, -2 / (zf - zn), tz,
			0, 0, 0, 1
		);
	}

	public inline function transpose():Matrix4 {
		return new Matrix4(
			this._11, this._21, this._31, this._41,
			this._12, this._22, this._32, this._42,
			this._13, this._23, this._33, this._43,
			this._14, this._24, this._34, this._44
		);
	}

	public inline function trace():Float {
		return this._11 + this._22 + this._33 + this._44;
	}

	@:op(A + V) inline static function add(a:Matrix4, b:Matrix4):Matrix4 {
		return new Matrix4(
			a._11 + b._11, a._12 + b._12, a._13 + b._13, a._14 + b._14,
			a._21 + b._21, a._22 + b._22, a._23 + b._23, a._24 + b._24,
			a._31 + b._31, a._32 + b._32, a._33 + b._33, a._34 + b._34,
			a._41 + b._41, a._42 + b._42, a._43 + b._43, a._44 + b._44
		);
	}

	@:commutative
	@:op(A + V) inline static function addv(a:Matrix4, b:Float):Matrix4 {
		return new Matrix4(
			a._11 + b, a._12 + b, a._13 + b, a._14 + b,
			a._21 + b, a._22 + b, a._23 + b, a._24 + b,
			a._31 + b, a._32 + b, a._33 + b, a._34 + b,
			a._41 + b, a._42 + b, a._43 + b, a._44 + b
		);
	}

	@:op(A - B) inline static function sub(a:Matrix4, b:Matrix4):Matrix4 {
		return new Matrix4(
			a._11 - b._11, a._12 - b._12, a._13 - b._13, a._14 - b._14,
			a._21 - b._21, a._22 - b._22, a._23 - b._23, a._24 - b._24,
			a._31 - b._31, a._32 - b._32, a._33 - b._33, a._34 - b._34,
			a._41 - b._41, a._42 - b._42, a._43 - b._43, a._44 - b._44
		);
	}

	@:op(A - B) inline static function subf(a:Matrix4, b:Float):Matrix4 {
		return new Matrix4(
			a._11 - b, a._12 - b, a._13 - b, a._14 - b,
			a._21 - b, a._22 - b, a._23 - b, a._24 - b,
			a._31 - b, a._32 - b, a._33 - b, a._34 - b,
			a._41 - b, a._42 - b, a._43 - b, a._44 - b
		);
	}

	@:op(A - B) inline static function fsub(a:Float, b:Matrix4):Matrix4 {
		return new Matrix4(
			a - b._11, a - b._12, a - b._13, a - b._14,
			a - b._21, a - b._22, a - b._23, a - b._24,
			a - b._31, a - b._32, a - b._33, a - b._34,
			a - b._41, a - b._42, a - b._43, a - b._44
		);
	}

	@:op(A * B) inline static function mult(a:Matrix4, b:Matrix4):Matrix4 {
		var a1 = new Vector4(a._11, a._12, a._13, a._14);
		var a2 = new Vector4(a._21, a._22, a._23, a._24);
		var a3 = new Vector4(a._31, a._32, a._33, a._34);
		var a4 = new Vector4(a._41, a._42, a._43, a._44);

		var b1 = new Vector4(b._11, b._21, b._31, b._41);
		var b2 = new Vector4(b._12, b._22, b._32, b._42);
		var b3 = new Vector4(b._13, b._23, b._33, b._43);
		var b4 = new Vector4(b._14, b._24, b._34, b._44);

		return new Matrix4(
			a1.dot(b1), a1.dot(b2), a1.dot(b3), a1.dot(b4),
			a2.dot(b1), a2.dot(b2), a2.dot(b3), a2.dot(b4),
			a3.dot(b1), a3.dot(b2), a3.dot(b3), a3.dot(b4),
			a4.dot(b1), a4.dot(b2), a4.dot(b3), a4.dot(b4)
		);
	}

	@:commutative
	@:op(A * B) inline static function multf(a:Matrix4, b:Float):Matrix4
		return new Matrix4(
			a._11 * b, a._12 * b, a._13 * b, a._14 * b,
			a._21 * b, a._22 * b, a._23 * b, a._24 * b,
			a._31 * b, a._32 * b, a._33 * b, a._34 * b,
			a._41 * b, a._42 * b, a._43 * b, a._44 * b
		);

	@:op(A * B) inline static function multv(a:Matrix4, b:Vector4):Vector4 {
		var a1 = new Vector4(a._11, a._12, a._13, a._14);
		var a2 = new Vector4(a._21, a._22, a._23, a._24);
		var a3 = new Vector4(a._31, a._32, a._33, a._34);
		var a4 = new Vector4(a._41, a._42, a._43, a._44);
		return new Vector4(a1.dot(b), a2.dot(b), a3.dot(b), a4.dot(b));
	}

	@:op(A == B) inline static function equal(a:Matrix4, b:Matrix4) {
		return a._11 == b._11 && a._12 == b._12 && a._13 == b._13 && a._14 == b._14 && a._21 == b._21 && a._22 == b._22 && a._23 == b._23 && a._24 == b._24
			&& a._31 == b._31 && a._32 == b._32 && a._33 == b._33 && a._34 == b._34 && a._41 == b._41 && a._42 == b._42 && a._43 == b._43 && a._44 == b._44;
	}

	@:to inline function toArray():Array<arcane.FastFloat> {
		return [
			this._11, this._12, this._13, this._14,
			this._21, this._22, this._23, this._24,
			this._31, this._32, this._33, this._34,
			this._41, this._42, this._43, this._44
		];
	}
}

private class Mat3Internal {
	public var _11:Float;
	public var _12:Float;
	public var _13:Float;
	public var _21:Float;
	public var _22:Float;
	public var _23:Float;
	public var _31:Float;
	public var _32:Float;
	public var _33:Float;

	public function new(_11, _12, _13, _21, _22, _23, _31, _32, _33) {
		this._11 = _11;
		this._12 = _12;
		this._13 = _13;
		this._21 = _21;
		this._22 = _22;
		this._23 = _23;
		this._31 = _31;
		this._32 = _32;
		this._33 = _33;
	}

	inline function toString() {
		return 'Matrix3 {\n $_11 $_12 $_13\n$_21 $_22 $_23\n$_31 $_32 $_33\n}';
	}
}

private class Mat4Internal {
	public var _11:Float;
	public var _12:Float;
	public var _13:Float;
	public var _14:Float;
	public var _21:Float;
	public var _22:Float;
	public var _23:Float;
	public var _24:Float;
	public var _31:Float;
	public var _32:Float;
	public var _33:Float;
	public var _34:Float;
	public var _41:Float;
	public var _42:Float;
	public var _43:Float;
	public var _44:Float;

	public inline function new(_11:Float, _12:Float, _13:Float, _14:Float, _21:Float, _22:Float, _23:Float, _24:Float, _31:Float, _32:Float, _33:Float,
			_34:Float, _41:Float, _42:Float, _43:Float, _44:Float) {
		this._11 = _11;
		this._12 = _12;
		this._13 = _13;
		this._14 = _14;
		this._21 = _21;
		this._22 = _22;
		this._23 = _23;
		this._24 = _24;
		this._31 = _31;
		this._32 = _32;
		this._33 = _33;
		this._34 = _34;
		this._41 = _41;
		this._42 = _42;
		this._43 = _43;
		this._44 = _44;
	}

	inline function toString() {
		return 'Matrix4 {\n$_11 $_12 $_13 $_14\n$_21 $_22 $_23 $_24\n$_31 $_32 $_33 $_34\n$_41 $_42 $_43 $_44\n}';
	}
}

private class Vec3Internal {
	public var x:Float;
	public var y:Float;
	public var z:Float;

	public inline function new(x, y, z) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	inline function toString():String {
		return 'Vector3 {$x $y $z}';
	}
}

private class Vec4Internal {
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var w:Float;

	public inline function new(x, y, z, w) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	inline function toString():String {
		return 'Vector4 {$x $y $z $w}';
	}
}