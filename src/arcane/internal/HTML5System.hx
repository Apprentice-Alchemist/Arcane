package arcane.internal;

import js.html.WheelEvent;
import js.html.KeyboardEvent;
import js.html.MouseEvent;
import js.html.CanvasElement;
import arcane.system.IGraphicsDriver;
import arcane.system.ISystem;
import js.html.webgl.GL;

@:access(arcane)
class HTML5System implements ISystem {
	public function new() {}

	public var window(default, null):IWindow;
	public var canvas:js.html.CanvasElement;

	public function init(opts:SystemOptions, cb:Void->Void):Void {
		if (!js.Browser.supported)
			throw "expected a browser environment";
		try {
			var cdef = haxe.macro.Compiler.getDefine("arcane.html5.canvas");
			// var cid = (opts != null && opts.html5 != null && opts.html5.canvas_id != null) ? opts.html5.canvas_id : ((cdef == "1" || cdef == null) ? "arcane" : cdef);
			var cid = cdef != null ? cdef : "arcane";
			canvas = cast js.Browser.window.document.getElementById(cid);
			if (canvas == null) {
				untyped alert('Could not find canvas with id ${cid}.');
				return;
			}
			inline function event(he:Dynamic,e:arcane.system.Event) {Lib.onEvent.trigger(e);}
			canvas.onmousedown = (e:MouseEvent) -> event(e,MouseDown(switch e.button {
				case 1: 0;
				case b: b;
			},e.clientX,e.clientY));
			canvas.onmouseup = (e:MouseEvent) -> event(e,MouseUp(e.button,e.clientX,e.clientY));
			canvas.onmousemove = (e:MouseEvent) -> event(e,MouseMove(-e.movementX,-e.movementY));
			canvas.onwheel = (e:WheelEvent) -> event(e,MouseWheel(e.deltaY));
			canvas.onblur = () -> event(null,FocusLost);
			canvas.onfocus = () -> event(null,FocusGained);

			// canvas.onkeypress = (e:KeyboardEvent) -> event(e,KeyPress(e.which));
			canvas.onkeydown = e -> trace("canvas",e.key);
			cb();
			js.Browser.window.requestAnimationFrame(update);
		} catch (e:haxe.Exception) {
			js.Browser.window.alert(e.details());
		}
	}

	private var lastTime = 0.0;

	public function update(dt:Float) {
		try {
			arcane.Lib.handle_update((dt - lastTime) / 1000);
			lastTime = dt;
			js.Browser.window.requestAnimationFrame(update);
		} catch (e) {
			js.Browser.window.alert(e.details());
		}
	}

	public function shutdown() {}

	// public function createAudioDriver():Null<IAudioDriver> {
	// 	return null;
	// }

	public function createGraphicsDriver(?options:GraphicsDriverOptions):Null<IGraphicsDriver> {
		// final canvas = if(options == null) this.canvas else options.canvas;
		var gl:GL = canvas.getContextWebGL2({alpha: false, antialias: false, stencil: true});
		var wgl2 = true;
		if (gl == null) {
			gl = canvas.getContextWebGL({alpha: false, antialias: false, stencil: true});
			wgl2 = false;
		}
		if (gl == null) {
			untyped alert("Could not aquire WebGL context.");
			return null;
		}
		return new arcane.internal.WebGLDriver(gl, canvas, wgl2);
	}

	public function language():String {
		return js.Browser.navigator.language;
	}

	public function time():Float {
		return lastTime / 1000.0;
	}

	public function width():Int {
		return canvas.width;
	}

	public function height():Int {
		return canvas.height;
	}

	public function lockMouse():Void {
		canvas.requestPointerLock();
	}

	public function unlockMouse():Void {
		js.Browser.document.exitPointerLock();
	}

	public function canLockMouse():Bool {
		return js.Syntax.code("'pointerLockElement' in document ||
		'mozPointerLockElement' in document ||
		'webkitPointerLockElement' in document");
	}

	public function isMouseLocked():Bool {
		return js.Syntax.code("document.pointerLockElement === {0} ||
			document.mozPointerLockElement === {0} ||
			document.webkitPointerLockElement === {0}", this.canvas);
	}

	public function showMouse():Void {}

	public function hideMouse():Void {}
}

private class HTML5Window implements IWindow {
	public var title(get, set):String;
	public var x(get, never):Int;
	public var y(get, never):Int;
	public var width(get, never):Int;
	public var height(get, never):Int;
	public var vsync(get, never):Bool;
	public var mode(get, set):WindowMode;

	var canvas:CanvasElement;

	public function new(canvas) {
		this.canvas = canvas;
	}

	public function get_title():String {
		return js.Browser.window.name;
	}

	public function set_title(value:String):String {
		return js.Browser.window.name = value;
	}

	public function get_x():Int {
		return 0;
	}

	public function get_y():Int {
		return 0;
	}

	public function get_width():Int {
		return canvas.width;
	}

	public function get_height():Int {
		return canvas.width;
	}

	public function get_vsync():Bool {
		return true;
	}

	public function get_mode():WindowMode {
		var doc = js.Browser.document;
		if (doc.fullscreenElement != null) {
			return Fullscreen;
		}

		return Windowed;
	}

	public function set_mode(value:WindowMode):WindowMode {
		var doc = js.Browser.document;
		// var elt:Dynamic = doc.documentElement;
		var fullscreen = value != Windowed;
		if ((doc.fullscreenElement == canvas) == fullscreen)
			return Windowed;
		if (value != Windowed)
			canvas.requestFullscreen();
		else
			doc.exitFullscreen();

		return value;
	}

	public function move(x:Int, y:Int) {}

	public function resize(width:Int, height:Int) {
		canvas.width = width;
		canvas.height = height;
	}
}
