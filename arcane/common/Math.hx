package arcane.common;

abstract Vector2(Dynamic){}
abstract Vector3(Dynamic){}
abstract Vector4(Dynamic){}

abstract Matrix3(Dynamic) {
    public inline function new(){}
    public inline function transpose():Matrix3 return null;
    public inline function trace():Float return 0.0;
    @:op(A + V) static inline function add(a:Matrix3,b:Matrix3):Matrix3 return null;
	@:op(A + V) static inline function addv(a:Matrix3, b:Float):Matrix3 return null;
    @:op(A - B) static inline function sub(a:Matrix3,b:Matrix3):Matrix3 return null;
    @:op(A - B) static inline function subv(a:Matrix3,b:Float):Matrix3 return null;
    @:op(A * B) static inline function mult(a:Matrix3,b:Matrix3):Matrix3 return null;
    @:op(A * B) static inline function multv(a:Matrix3,b:Float):Matrix3 return null;
    @:op(A * B) static inline function multvec(a:Matrix3,b:Vector3):Vector3 return null;
}

abstract Matrix4(Dynamic) {
    public inline function new(){}
    public inline function transpose():Matrix4 return null;
    public inline function trace():Float return 0.0;
    @:op(A + V) static inline function add(a:Matrix4,b:Matrix4):Matrix4 return null;
	@:op(A + V) static inline function addv(a:Matrix4, b:Float):Matrix4 return null;
    @:op(A - B) static inline function sub(a:Matrix4,b:Matrix4):Matrix4 return null;
    @:op(A - B) static inline function subv(a:Matrix4,b:Float):Matrix4 return null;
    @:op(A * B) static inline function mult(a:Matrix4,b:Matrix4):Matrix4 return null;
    @:op(A * B) static inline function multv(a:Matrix4,b:Float):Matrix4 return null;
    @:op(A * B) static inline function multvec(a:Matrix4,b:Vector4):Vector4 return null;
}