package arcane.internal;

import kinc.input.Mouse;
import arcane.system.IGraphicsDriver;
import arcane.system.ISystem;

@:access(arcane)
class KincSystem implements ISystem {
	public var window(default, null):IWindow;

	public function new() {
		window = new KincWindow(0, "");
	}

	public function init(opts:SystemOptions, cb:Void->Void):Void {
		try {
			@:bypassAccessor window.title = opts.window_options.title;
			if (kinc.System.init(opts.window_options.title, 500, 500, {
				title: opts.window_options.title,
				y: opts.window_options.x,
				x: opts.window_options.y,
				window_features: MINIMIZABLE | MAXIMIZABLE | RESIZEABLE,
				width: opts.window_options.width,
				height: opts.window_options.height,
				visible: true,
				mode: switch opts.window_options.mode {
					case Windowed: WINDOWED;
					case Fullscreen: FULLSCREEN;
				},
				display_index: 0
			}, {
				vertical_sync: opts.window_options.vsync,
				stencil_bits: 8,
				samples_per_pixel: 1,
				frequency: 60,
				depth_bits: 16,
				color_bits: 32
			}) != 0)
				throw "init error";

			kinc.System.setUpdateCallback(update);
			kinc.System.setShutdownCallback(() -> arcane.Lib.exit(0));

			inline function event(e:arcane.system.Event) arcane.Lib.onEvent.trigger(e);

			kinc.input.Keyboard.setKeyDownCallback(key -> event(KeyDown(cast key)));
			kinc.input.Keyboard.setKeyUpCallback(key -> event(KeyUp(cast key)));
			kinc.input.Keyboard.setKeyPressCallback(code -> event(KeyPress(code)));

			kinc.input.Mouse.setPressCallback((window, button, x, y) -> event(MouseDown(button, x, y)));
			kinc.input.Mouse.setScrollCallback((_, delta) -> event(MouseWheel(delta)));
			kinc.input.Mouse.setReleaseCallback((window, button, x, y) -> event(MouseUp(button, x, y)));
			kinc.input.Mouse.setEnterWindowCallback(window -> event(MouseEnter));
			kinc.input.Mouse.setLeaveWindowCallback(window -> event(MouseLeave));
			kinc.input.Mouse.setMoveCallback((window, x, y, mov_x, mov_y) -> event(MouseMove(mov_x, mov_y)));

			kinc.Window.setResizeCallback(0, (i1, i2) -> event(Resize(i1, i2)));

			kinc.System.setBackgroundCallback(() -> event(FocusLost));
			kinc.System.setForegroundCallback(() -> event(FocusGained));

			cb();
			kinc.System.start();
		} catch (e) {
			trace(e.details());
			Sys.exit(-1);
		}
	}

	private var lastTime = 0.0;

	public function update() {
		try {
			var curtime = kinc.System.time();
			var dt = curtime - lastTime;
			lastTime = curtime;
			arcane.Lib.handle_update(dt);
			// kinc.g4.Graphics4.swapBuffers();
		} catch (e) {
			trace(e.details());
			kinc.System.stop();
		}
	}

	public function shutdown():Void {
		kinc.System.stop();
	}

	// public function createAudioDriver():Null<IAudioDriver> {
	// 	return null;
	// }

	public function createGraphicsDriver(?options:GraphicsDriverOptions):Null<IGraphicsDriver> {
		// var window = if(options == null) 0 else options.window;
		return new KincDriver(0);
	}

	public function language():String {
		return kinc.System.language().toString();
	}

	public function time():Float {
		return kinc.System.time();
	}

	public function width():Int {
		return kinc.System.width();
	}

	public function height():Int {
		return kinc.System.height();
	}

	public function lockMouse():Void {
		Mouse.lock(0);
	}

	public function unlockMouse():Void {
		Mouse.unlock(0);
	}

	public function canLockMouse():Bool {
		return Mouse.canLock(0);
	}

	public function isMouseLocked():Bool {
		return Mouse.isLocked(0);
	}

	public function showMouse():Void {
		Mouse.show();
	}

	public function hideMouse():Void {
		Mouse.hide();
	}

	public function readFile(name:String):haxe.io.Bytes {
		var reader = new kinc.io.FileReader();
		if (reader.open(name, AssetFile)) {
			var size = reader.size();
			var bytes = new hl.Bytes(size);
			if (reader.read(bytes, size) != size)
				throw "assert";
			reader.close();
			return bytes.toBytes(size);
		} else {
			throw "assert";
		}
	}
}

@:allow(KincSystem)
private class KincWindow implements IWindow {
	var index:Int = 0;

	@:isVar public var title(get, set):String;
	public var x(get, never):Int;
	public var y(get, never):Int;
	public var width(get, never):Int;
	public var height(get, never):Int;
	public var vsync(get, never):Bool;
	public var mode(get, set):WindowMode;

	public function new(index:Int, title:String) {
		this.index = index;
		@:bypassAccessor this.title = title;
	}

	public function resize(width:Int, height:Int):Void {
		kinc.Window.resize(index, width, height);
	}

	public function move(x:Int, y:Int):Void {
		kinc.Window.move(index, x, y);
	}

	function set_title(value:String):String {
		kinc.Window.setTitle(index, value);
		return value;
	}

	function get_title():String {
		return @:bypassAccessor title;
	}

	function get_x():Int {
		return kinc.Window.x(index);
	}

	function get_y():Int {
		return kinc.Window.y(index);
	}

	public function get_width():Int {
		return kinc.Window.width(index);
	}

	public function get_height():Int {
		return kinc.Window.height(index);
	}

	public function get_vsync():Bool {
		return kinc.Window.vsynced(index);
	}

	public function get_mode():WindowMode {
		return switch kinc.Window.getMode(index) {
			case WINDOWED: Windowed;
			case FULLSCREEN: Fullscreen;
			case EXCLUSIVE_FULLSCREEN: Fullscreen;
		}
	}

	public function set_mode(value:WindowMode):WindowMode {
		kinc.Window.changeMode(index, switch value {
			case Windowed: WINDOWED;
			case Fullscreen: FULLSCREEN;
		});
		return value;
	}
}
