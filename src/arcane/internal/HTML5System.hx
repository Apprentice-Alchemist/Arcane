package arcane.internal;

import arcane.system.IGraphicsDriver;
import arcane.system.ISystem;
import js.html.webgl.GL;

@:access(arcane)
class HTML5System implements ISystem {
	public function new() {}

	public var canvas:js.html.CanvasElement;

	public function init(opts:SystemOptions, cb:Void->Void):Void {
		if (!js.Browser.supported)
			throw "expected a browser environment";
		try {
			var cdef = haxe.macro.Compiler.getDefine("arcane.html5.canvas");
			var cid = (opts != null && opts.html5 != null && opts.html5.canvas_id != null) ? opts.html5.canvas_id : ((cdef == "1" || cdef == null) ? "arcane" : cdef);
			canvas = cast js.Browser.window.document.getElementById(cid);
			if (canvas == null) {
				untyped alert('Could not find canvas with id ${cid}.');
				return;
			}
			cb();
			js.Browser.window.requestAnimationFrame(update);
		} catch (e:haxe.Exception) {
			js.Browser.window.alert(e.details());
		}
	}

	private var lastTime = 0.0;

	public function update(dt:Float) {
		try {
			arcane.Lib.update((dt - lastTime) / 1000);
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

	public function createGraphicsDriver():Null<IGraphicsDriver> {
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
}
