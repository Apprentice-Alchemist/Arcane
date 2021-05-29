package arcane.internal.empty;

import arcane.system.ISystem;
import arcane.system.IAudioDriver;
import arcane.system.IGraphicsDriver;
import arcane.system.Event;

class System implements ISystem {
	public function new() {
		window = new Window();
	}

	public function init(opts, cb:Void->Void):Void {
		cb();
		var stamp = haxe.Timer.stamp();
		while (true) {
			if (sd)
				break;
			var dt = haxe.Timer.stamp() - stamp;
			stamp += dt;
			arcane.Lib.handle_update(dt);
		}
	}

	private var sd = false;

	public function shutdown():Void {
		sd = true;
	}

	public function createAudioDriver():Null<IAudioDriver> {
		return null;
	}

	public function createGraphicsDriver(?opts):Null<IGraphicsDriver> {
		return new GraphicsDriver();
	}

	public function language():String {
		return "en";
	}

	public function time():Float {
		return 0.0;
	}

	public function width():Int {
		return 0;
	}

	public function height():Int {
		return 0;
	}

	public var window(default, null):IWindow;

	public function lockMouse():Void {}

	public function unlockMouse():Void {}

	public function canLockMouse():Bool {
		return false;
	}

	public function isMouseLocked():Bool {
		return false;
	}

	public function showMouse():Void {}

	public function hideMouse():Void {}
}

private class Window implements IWindow {
	public var title(get, set):String;
	public var x(get, never):Int;
	public var y(get, never):Int;
	public var width(get, never):Int;
	public var height(get, never):Int;
	public var vsync(get, never):Bool;
	public var mode(get, set):WindowMode;

	public function new() {}

	public function get_title():String {
		return "";
	}

	public function set_title(value:String):String {
		return value;
	}

	public function get_x():Int {
		return 0;
	}

	public function get_y():Int {
		return 0;
	}

	public function get_width():Int {
		return 800;
	}

	public function get_height():Int {
		return 600;
	}

	public function get_vsync():Bool {
		return true;
	}

	public function get_mode():WindowMode {
		return Windowed;
	}

	public function set_mode(value:WindowMode):WindowMode {
		return value;
	}

	public function move(x:Int, y:Int) {}

	public function resize(width:Int, height:Int) {}
}
