package asl;

// @:generic
// extern function __builtin_array_get<T, @:const L>(a:Array<T, L>, index:Int):T;

@:coreType
abstract Array<T, @:const L:Int> {
	@:arrayAccess extern function get(index:Int):T;
}

typedef A = Array<Int, 1>;

@:builtin(vec2)
@:coreType abstract Vec2<T = Float> {
	@:resolve static macro function resolve<T>(self:haxe.macro.Expr.ExprOf<Vec2<T>>, name:String):haxe.macro.Expr.ExprOf<T> {
		return macro cast null;
	}
}

function test() {
	var v:Vec2<Float> = cast null;
	var v = v.xy;
}

@:builtin(vec3)
@:coreType abstract Vec3<T = Float> {
	public var x(get, set):T;

	inline function get_x() {
		return untyped __builtin_vec4_get_x(this);
	}

	inline function set_x(value:T) {
		return untyped __builtin_vec4_set_x(this);
	}

	public var y(get, set):T;

	inline function get_y() {
		return untyped __builtin_vec4_get_x(this);
	}

	inline function set_y(value:T) {
		return untyped __builtin_vec4_set_x(this);
	}

	public var z(get, set):T;

	inline function get_z() {
		return untyped __builtin_vec4_get_x(this);
	}

	inline function set_z(value:T) {
		return untyped __builtin_vec4_set_x(this);
	}
}

@:builtin(vec4)
@:coreType abstract Vec4<T = Float> {
	public var x(get, set):T;

	inline function get_x() {
		return untyped __builtin_vec4_get_x(this);
	}

	inline function set_x(value:T) {
		return untyped __builtin_vec4_set_x(this);
	}

	@:op(A + B)
	inline static function add<T>(a:Vec4<T>, b:Vec4<T>):Vec4<T> {
		return untyped __builtin_add_vec4(a, b);
	}

	@:commutative
	@:op(A + B) inline static function addValue<T>(a:Vec4<T>, b:T):Vec4<T> {
		return a + vec4(b);
	}
}

@:builtin(mat4)
@:coreType abstract Mat4<T = Float> {
	@:op(A * B) inline function mulVec(b:Vec4<T>):Vec4<T> {
		return untyped __builtin_mat4_mul_vec4(this, b);
	}
}

@:builtin(texture2d)
@:coreType abstract Texture2D {
	public function get(coord:Vec2<Float>):Vec4<Float> {
		return untyped __builtin_texture_get(this, coord);
	}
}

extern inline overload function vec4<T>(a:T):Vec4<T> {
	return vec4(a, a, a, a);
}

extern inline overload function vec4<T>(a:Vec3<T>, value:T) {
	return vec4(a.x, a.y, a.z, value);
}

@:builtin(vec4_from_values)
extern overload function vec4<T>(a:T, b:T, c:T, d:T):Vec4<T>;

@:builtin(mix_vec4)
extern function mix<T>(a:Vec4<T>, b:Vec4<T>, v:T):Vec4<T>;