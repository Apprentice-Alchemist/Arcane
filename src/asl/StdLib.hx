package asl;

import asl.Ast;

private extern function __builtin_vec2_get_x<T>(v:Vec2<T>):T;
private extern function __builtin_vec2_get_y<T>(v:Vec2<T>):T;
private extern function __builtin_vec2_set_x<T>(v:Vec2<T>, value:T):T;
private extern function __builtin_vec2_set_y<T>(v:Vec2<T>, value:T):T;
private extern function __builtin_vec3_get_x<T>(v:Vec3<T>):T;
private extern function __builtin_vec3_get_y<T>(v:Vec3<T>):T;
private extern function __builtin_vec3_get_z<T>(v:Vec3<T>):T;
private extern function __builtin_vec3_set_x<T>(v:Vec3<T>, value:T):T;
private extern function __builtin_vec3_set_y<T>(v:Vec3<T>, value:T):T;
private extern function __builtin_vec3_set_z<T>(v:Vec3<T>, value:T):T;
private extern function __builtin_vec4_get_x<T>(v:Vec4<T>):T;
private extern function __builtin_vec4_get_y<T>(v:Vec4<T>):T;
private extern function __builtin_vec4_get_z<T>(v:Vec4<T>):T;
private extern function __builtin_vec4_get_w<T>(v:Vec4<T>):T;
private extern function __builtin_vec4_set_x<T>(v:Vec4<T>, value:T):T;
private extern function __builtin_vec4_set_y<T>(v:Vec4<T>, value:T):T;
private extern function __builtin_vec4_set_z<T>(v:Vec4<T>, value:T):T;
private extern function __builtin_vec4_set_w<T>(v:Vec4<T>, value:T):T;
private extern function __builtin_texture_get(t:Texture2D, coord:Vec2<Float>):Vec4<Float>;
private extern function __builtin_mat4_mul_vec4<T>(m:Mat4<T>, v:Vec4<T>):Vec4<T>;
private extern function __builtin_vec4_add<T>(a:Vec4<T>, b:Vec4<T>):Vec4<T>;
private extern function __builtin_vec4_from_values<T>(a:T, b:T, c:T, d:T):Vec4<T>;
private extern function __builtin_vec4_mix<T>(a:Vec4<T>, b:Vec4<T>, v:T):Vec4<T>;
private extern function __builtin_vec3_from_values<T>(a:T, b:T, c:T):Vec3<T>;
private extern function __builtin_vec2_from_values<T>(a:T, b:T):Vec2<T>;

@:coreType
abstract Array<T, @:const L:Int> {
	@:arrayAccess extern function get(index:Int):T;
	
}

#if macro
function swizzle(self:haxe.macro.Expr, size:Int, name:String) {
	final str = "xrsygtzbpwaq";
	var cat = -1;
	final out = [];
	for (i in 0...name.length) {
		var idx = str.indexOf(name.charAt(i));
		if (idx < 0)
			throw "err";
		var icat = idx % 3;
		if (cat < 0)
			cat = icat
		else if (icat != cat)
			break; // down't allow .ryz
		var cid = Std.int(idx / 3);
		if (cid >= size)
			throw "err";
		// error(typeToString(e.t) + " does not have component " + name.charAt(i), e.pos);
		out.push(cid);
	}
	var comps = out.map(c -> switch c {
		case 0: macro $self.x;
		case 1: macro $self.y;
		case 2: macro $self.z;
		case 3: macro $self.w;
		case _: throw "assert";
	});

	return switch size {
		case 2: macro vec2($a{comps});
		case 3: macro vec3($a{comps});
		case 4: macro vec4($a{comps});
		case var l: throw "assert";
	}
}
#end

@:builtin(vec2)
@:coreType abstract Vec2<T #if (haxe_ver >= 4.3) = Float #end> {
	public var x(get, set):T;

	extern inline function get_x() {
		return __builtin_vec2_get_x(this);
	}

	extern inline function set_x(value:T) {
		return __builtin_vec2_set_x(this, value);
	}

	public var y(get, set):T;

	extern inline function get_y() {
		return __builtin_vec2_get_y(this);
	}

	extern inline function set_y(value:T) {
		return __builtin_vec2_set_y(this, value);
	}

	@:resolve static macro function resolve<T>(self:haxe.macro.Expr.ExprOf<Vec2<T>>, name:String):haxe.macro.Expr.ExprOf<T> {
		return swizzle(self, 2, name);
	}
}

@:builtin(vec3)
@:coreType abstract Vec3<T #if (haxe_ver >= 4.3) = Float #end> {
	public var x(get, set):T;

	extern inline function get_x() {
		return __builtin_vec3_get_x(this);
	}

	extern inline function set_x(value:T) {
		return __builtin_vec3_set_x(this, value);
	}

	public var y(get, set):T;

	extern inline function get_y() {
		return __builtin_vec3_get_y(this);
	}

	extern inline function set_y(value:T) {
		return __builtin_vec3_set_y(this, value);
	}

	public var z(get, set):T;

	extern inline function get_z() {
		return __builtin_vec3_get_x(this);
	}

	extern inline function set_z(value:T) {
		return __builtin_vec3_set_z(this, value);
	}

	@:resolve static macro function resolve<T>(self:haxe.macro.Expr.ExprOf<Vec2<T>>, name:String):haxe.macro.Expr.ExprOf<T> {
		return swizzle(self, 3, name);
	}
}

@:builtin(vec4)
@:coreType abstract Vec4<T #if (haxe_ver >= 4.3) = Float #end> {
	public var x(get, set):T;

	extern inline function get_x() {
		return __builtin_vec4_get_x(this);
	}

	extern inline function set_x(value:T) {
		return __builtin_vec4_set_x(this, value);
	}

	public var y(get, set):T;

	extern inline function get_y() {
		return __builtin_vec4_get_y(this);
	}

	extern inline function set_y(value:T) {
		return __builtin_vec4_set_y(this, value);
	}

	public var z(get, set):T;

	extern inline function get_z() {
		return __builtin_vec4_get_z(this);
	}

	extern inline function set_z(value:T) {
		return __builtin_vec4_set_z(this, value);
	}

	public var w(get, set):T;

	extern inline function get_w() {
		return __builtin_vec4_get_w(this);
	}

	extern inline function set_w(value:T) {
		return __builtin_vec4_set_w(this, value);
	}

	@:op(A + B)
	extern inline static function add<T>(a:Vec4<T>, b:Vec4<T>):Vec4<T> {
		return __builtin_vec4_add(a, b);
	}

	@:commutative
	@:op(A + B)
	extern inline static function addValue<T>(a:Vec4<T>, b:T):Vec4<T> {
		return a + vec4(b);
	}

	@:resolve static macro function resolve<T>(self:haxe.macro.Expr.ExprOf<Vec2<T>>, name:String):haxe.macro.Expr.ExprOf<T> {
		return swizzle(self, 4, name);
	}
}

@:builtin(mat4)
@:coreType abstract Mat4<T #if (haxe_ver >= 4.3) = Float #end> {
	@:op(A * B) extern inline function mulVec(b:Vec4<T>):Vec4<T> {
		return __builtin_mat4_mul_vec4(this, b);
	}
}

@:builtin(texture2d)
@:coreType abstract Texture2D {
	public extern inline function get(coord:Vec2<Float>):Vec4<Float> {
		return __builtin_texture_get(this, coord);
	}
}

extern inline overload function vec2<T>(a:T):Vec2<T> {
	return vec2(a, a);
}

extern inline overload function vec2<T>(a:T, b:T):Vec2<T> {
	return __builtin_vec2_from_values(a, b);
}

extern inline overload function vec3<T>(a:T):Vec3<T> {
	return vec3(a, a, a);
}

extern inline overload function vec3<T>(a:Vec2<T>, value:T):Vec3<T> {
	return vec3(a.x, a.y, value);
}

extern inline overload function vec3<T>(a:T, b:T, c:T):Vec3<T> {
	return __builtin_vec3_from_values(a, b, c);
}

extern inline overload function vec4<T>(a:T):Vec4<T> {
	return vec4(a, a, a, a);
}

extern inline overload function vec4<T>(a:Vec3<T>, value:T) {
	return vec4(a.x, a.y, a.z, value);
}

extern inline overload function vec4<T>(a:T, b:T, c:T, d:T):Vec4<T> {
	return __builtin_vec4_from_values(a, b, c, d);
}

extern inline function mix<T>(a:Vec4<T>, b:Vec4<T>, v:T):Vec4<T> {
	return __builtin_vec4_mix(a, b, v);
}
