package arcane.d2d;

class Object {
	private var posChanged:Bool = false;
	private var children:Array<Object> = [];

	public var x(default, set):Float = 0;
	public var y(default, set):Float = 0;

	public var scaleX(default, set):Float = 1;
	public var scaleY(default, set):Float = 1;

	public var rotation(default, set):Float = 0;

	public var visible:Bool = true;

	public var alpha:Float = 1;

	public var numChildren(get, never):Int;

	public var parent(default, null):Object;

	public function new(?parent:Object) {}

	inline function get_numChildren():Int return children.length;

	inline function set_x(f:Float) {
		posChanged = true;
		x = f;
		return f;
	}

	inline function set_y(f:Float) {
		posChanged = true;
		y = f;
		return f;
	}

	inline function set_scaleX(f:Float) {
		posChanged = true;
		scaleX = f;
		return f;
	}

	inline function set_scaleY(f:Float) {
		posChanged = true;
		scaleY = f;
		return f;
	}

	inline function set_rotation(f:Float) {
		posChanged = true;
		rotation = f;
		return f;
	}
}
