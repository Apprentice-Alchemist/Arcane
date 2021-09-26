package arcane.util;

// causes a `copy(fpu,cpu)` error on hashlink
// @:eager private typedef Float = arcane.FastFloat;

@:pure
@:forward
abstract Vector3(Vec3Internal) {
	public inline static function empty():Vector3 {
		return new Vector3(0, 0, 0);
	}

	public inline function dot(b:Vector3):Float {
		return this.x * b.x + this.y * b.y + this.z * b.z;
	}

	public inline function new(x:Float, y:Float, z:Float) {
		this = new Vec3Internal(x, y, z);
	}

	@:op(A == B) inline static function equals(a:Vector3, b:Vector3) {
		return a.x == b.x && a.y == b.y && a.z == b.z;
	}
}

@:pure
@:forward
abstract Vector4(Vec4Internal) {
	public inline static function empty():Vector4 {
		return new Vector4(0, 0, 0, 0);
	}

	public inline function dot(b:Vector4):Float {
		return this.x * b.x + this.y * b.y + this.z * b.z + this.w * b.w;
	}

	public inline function mult(b:Vector4):Vector4 {
		return new Vector4(this.x * b.x, this.y * b.y, this.z * b.z, this.w * b.w);
	}

	public inline function new(x:Float, y:Float, z:Float, w:Float) {
		this = new Vec4Internal(x, y, z, w);
	}

	@:op(A == B) inline static function equals(a:Vector4, b:Vector4) {
		return a.x == b.x && a.y == b.y && a.z == b.z && a.w == b.w;
	}
}

@:pure
@:forward
abstract Matrix3(Mat3Internal) {
	public static inline var SIZE = 4 * 9;

	public static inline function rotationX(alpha:Float):Matrix3 {
		var ca:Float = Math.cos(alpha);
		var sa:Float = Math.sin(alpha);
		return new Matrix3(
			1, 0, 0,
			0, ca, -sa,
			0, sa, ca
		);
	}

	public static inline function rotationY(alpha:Float):Matrix3 {
		var ca:Float = Math.cos(alpha);
		var sa:Float = Math.sin(alpha);
		return new Matrix3(
			ca, 0, sa,
			0, 1, 0,
			-sa, 0, ca
		);
	}

	public static inline function rotationZ(alpha:Float):Matrix3 {
		var ca:Float = Math.cos(alpha);
		var sa:Float = Math.sin(alpha);
		return new Matrix3(
			ca, -sa, 0,
			sa, 1, 0,
			ca, 0, 1
		);
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

	public inline function new(_11:Float, _12:Float, _13:Float, _21:Float, _22:Float, _23:Float, _31:Float, _32:Float, _33:Float) {
		this = new Mat3Internal(
			_11, _12, _13,
			_21, _22, _23,
			_31, _32, _33
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
		var a1 = inline new Vector3(a._11, a._12, a._13);
		var a2 = inline new Vector3(a._21, a._22, a._23);
		var a3 = inline new Vector3(a._31, a._32, a._33);

		var b1 = inline new Vector3(b._11, b._21, b._31);
		var b2 = inline new Vector3(b._12, b._22, b._32);
		var b3 = inline new Vector3(b._13, b._23, b._33);

		return new Matrix3(
			inline a1.dot(b1), inline a1.dot(b2), inline a1.dot(b3),
			inline a2.dot(b1), inline a2.dot(b2), inline a2.dot(b3),
			inline a3.dot(b1), inline a3.dot(b2), inline a3.dot(b3)
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
		var a1 = inline new Vector3(a._11, a._12, a._13);
		var a2 = inline new Vector3(a._21, a._22, a._23);
		var a3 = inline new Vector3(a._31, a._32, a._33);

		return new Vector3(inline a1.dot(b), inline a2.dot(b), inline a3.dot(b));
	}
}

@:pure
@:forward
abstract Matrix4(Mat4Internal) {
	public static inline var SIZE = 4 * 16;

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
			1, 0, 0, x,
			0, 1, 0, y,
			0, 0, 1, z,
			0, 0, 0, 1
		);
	}

	public inline static function homogeneousOrthographic(left:Float, right:Float, top:Float, bottom:Float, near:Float, far:Float):Matrix4 {
		final a = 2 / (right - left);
		final b = 2 / (top - bottom);
		final c = -2 / (far - near);

		return new Matrix4(
			a, 0, 0, -(right + left) / (right - left),
			0, b, 0, -(top + bottom) / (top - bottom),
			0, 0, c, -(far + near) / (far - near),
			0, 0, 0, 1
		);
	}

	public inline static function heterogeneousOrthographic(left:Float, right:Float, top:Float, bottom:Float, near:Float, far:Float):Matrix4 {
		final a = 2 / (right - left);
		final b = 2 / (top - bottom);
		final c = -1 / (far - near);

		return new Matrix4(
			a, 0, 0, -(right + left) / (right - left),
			0, b, 0, -(top + bottom) / (top - bottom),
			0, 0, c, -near / (far - near),
			0, 0, 0, 1
		);
	}

	public inline static function homogeneousPerspective(fov:Float, aspect:Float, near:Float, far:Float):Matrix4 {
		final tanHalfFov = Math.tan(fov / 2);
		final a = 1 / (aspect * tanHalfFov);
		final b = 1 / tanHalfFov;
		final c = -(far + near) / (far - near);
		final d = -1;
		final e = -(2 * far * near) / (far - near);

		return new Matrix4(
			a, 0, 0, 0,
			0, b, 0, 0,
			0, 0, c, e,
			0, 0, d, 0
		);
	}

	public inline static function heterogeneousPerspective(fov:Float, aspect:Float, near:Float, far:Float):Matrix4 {
		final tanHalfFov = Math.tan(fov / 2);
		final a = 1 / (aspect * tanHalfFov);
		final b = 1 / tanHalfFov;
		final c = far / (near - far);
		final d = -1;
		final e = -(far * near) / (far - near);

		return new Matrix4(
			a, 0, 0, 0,
			0, b, 0, 0,
			0, 0, c, e,
			0, 0, d, 0
		);
	}

	public inline function new(_11:Float, _12:Float, _13:Float, _14:Float, _21:Float, _22:Float, _23:Float, _24:Float, _31:Float, _32:Float, _33:Float,
			_34:Float, _41:Float, _42:Float, _43:Float, _44:Float) {
		this = new Mat4Internal(
			_11, _12, _13, _14,
			_21, _22, _23, _24,
			_31, _32, _33, _34,
			_41, _42, _43, _44
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
		var a1 = inline new Vector4(a._11, a._12, a._13, a._14);
		var a2 = inline new Vector4(a._21, a._22, a._23, a._24);
		var a3 = inline new Vector4(a._31, a._32, a._33, a._34);
		var a4 = inline new Vector4(a._41, a._42, a._43, a._44);

		var b1 = inline new Vector4(b._11, b._21, b._31, b._41);
		var b2 = inline new Vector4(b._12, b._22, b._32, b._42);
		var b3 = inline new Vector4(b._13, b._23, b._33, b._43);
		var b4 = inline new Vector4(b._14, b._24, b._34, b._44);

		return new Matrix4(
			inline a1.dot(b1), inline a1.dot(b2), inline a1.dot(b3), inline a1.dot(b4),
			inline a2.dot(b1), inline a2.dot(b2), inline a2.dot(b3), inline a2.dot(b4),
			inline a3.dot(b1), inline a3.dot(b2), inline a3.dot(b3), inline a3.dot(b4),
			inline a4.dot(b1), inline a4.dot(b2), inline a4.dot(b3), inline a4.dot(b4)
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
		var a1 = inline new Vector4(a._11, a._12, a._13, a._14);
		var a2 = inline new Vector4(a._21, a._22, a._23, a._24);
		var a3 = inline new Vector4(a._31, a._32, a._33, a._34);
		var a4 = inline new Vector4(a._41, a._42, a._43, a._44);
		return new Vector4(inline a1.dot(b), inline a2.dot(b), inline a3.dot(b), inline a4.dot(b));
	}

	@:op(A == B) inline static function equal(a:Matrix4, b:Matrix4) {
		return a._11 == b._11 && a._12 == b._12 && a._13 == b._13 && a._14 == b._14 && a._21 == b._21 && a._22 == b._22 && a._23 == b._23 && a._24 == b._24
			&& a._31 == b._31 && a._32 == b._32 && a._33 == b._33 && a._34 == b._34 && a._41 == b._41 && a._42 == b._42 && a._43 == b._43 && a._44 == b._44;
	}

	@:to inline function toArray():Array<Float> {
		return [
			this._11, this._12, this._13, this._14,
			this._21, this._22, this._23, this._24,
			this._31, this._32, this._33, this._34,
			this._41, this._42, this._43, this._44
		];
	}
}

private class Mat3Internal {
	public final _11:Float;
	public final _12:Float;
	public final _13:Float;
	public final _21:Float;
	public final _22:Float;
	public final _23:Float;
	public final _31:Float;
	public final _32:Float;
	public final _33:Float;

	public inline function new(_11, _12, _13, _21, _22, _23, _31, _32, _33) {
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
	public final _11:Float;
	public final _12:Float;
	public final _13:Float;
	public final _14:Float;
	public final _21:Float;
	public final _22:Float;
	public final _23:Float;
	public final _24:Float;
	public final _31:Float;
	public final _32:Float;
	public final _33:Float;
	public final _34:Float;
	public final _41:Float;
	public final _42:Float;
	public final _43:Float;
	public final _44:Float;

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
	public final x:Float;
	public final y:Float;
	public final z:Float;

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
	public final x:Float;
	public final y:Float;
	public final z:Float;
	public final w:Float;

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
