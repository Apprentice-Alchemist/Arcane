package asl.std;

import asl.std.StdLib;

extern class Builtins {
	static extern function vec2_get_x<T>(v:Vec2<T>):T;
	static extern function vec2_get_y<T>(v:Vec2<T>):T;
	static extern function vec2_set_x<T>(v:Vec2<T>, value:T):T;
	static extern function vec2_set_y<T>(v:Vec2<T>, value:T):T;
	static extern function vec3_get_x<T>(v:Vec3<T>):T;
	static extern function vec3_get_y<T>(v:Vec3<T>):T;
	static extern function vec3_get_z<T>(v:Vec3<T>):T;
	static extern function vec3_set_x<T>(v:Vec3<T>, value:T):T;
	static extern function vec3_set_y<T>(v:Vec3<T>, value:T):T;
	static extern function vec3_set_z<T>(v:Vec3<T>, value:T):T;
	static extern function vec4_get_x<T>(v:Vec4<T>):T;
	static extern function vec4_get_y<T>(v:Vec4<T>):T;
	static extern function vec4_get_z<T>(v:Vec4<T>):T;
	static extern function vec4_get_w<T>(v:Vec4<T>):T;
	static extern function vec4_set_x<T>(v:Vec4<T>, value:T):T;
	static extern function vec4_set_y<T>(v:Vec4<T>, value:T):T;
	static extern function vec4_set_z<T>(v:Vec4<T>, value:T):T;
	static extern function vec4_set_w<T>(v:Vec4<T>, value:T):T;
	static extern function texture_get(t:Texture2D, coord:Vec2<Float>):Vec4<Float>;
	static extern function mat4_mul_vec4<T>(m:Mat4<T>, v:Vec4<T>):Vec4<T>;
	static extern function vec4_add<T>(a:Vec4<T>, b:Vec4<T>):Vec4<T>;
	static extern function vec4_from_values<T>(a:T, b:T, c:T, d:T):Vec4<T>;
	static extern function vec3_from_values<T>(a:T, b:T, c:T):Vec3<T>;
	static extern function vec2_from_values<T>(a:T, b:T):Vec2<T>;
	static extern function mix<T, V:VecType<T>>(a:V, b:V, v:T):V;
	static extern function dot<T, V:VecType<T>>(a:V, b:V):T;
}
