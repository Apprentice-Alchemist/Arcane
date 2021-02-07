package backend.html5;

import arcane.spec.IAudioDriver;
import arcane.spec.IGraphicsDriver;
import arcane.spec.ISystem;
import js.html.webgl.GL;

@:access(arcane)
class System implements ISystem {
	public function isFeatureSupported(f:SystemFeature):Bool
		return switch f {
			case Graphics3D: true;
			case Audio: true;
		}

	public function new() {}

	public var canvas:js.html.CanvasElement;

	public function init(opts:SystemOptions, cb:Void->Void):Void try {
		var cdef = haxe.macro.Compiler.getDefine("arcane.html5.canvas");
		var cid = (opts != null && opts.html5 != null && opts.html5.canvas_id != null) ? opts.html5.canvas_id : ((cdef == "1" || cdef == null) ? "arcane" : cdef);
		canvas = cast js.Browser.window.document.getElementById(cid);
		if (canvas == null) {
			untyped alert('Could not find canvas with id ${cid}.');
			return;
		}
		cb();
		js.Browser.window.requestAnimationFrame(update);
	} catch (e:haxe.Exception)
		js.Browser.window.alert(e.details());

	private var lastTime = 0.0;

	public function update(dt:Float) try {
		arcane.Lib.update((dt - lastTime) / 1000);
		lastTime = dt;
		if (!sd)
			js.Browser.window.requestAnimationFrame(update);
	} catch (e)
		js.Browser.window.alert(e.details());

	var sd = false;

	public function shutdown() {
		sd = true;
	}

	public function createAudioDriver():Null<IAudioDriver>
		return null;

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
		return new WebGLDriver(gl, canvas, wgl2);
	}

	public function language():String
		return js.Browser.navigator.language;

	public function time():Float
		return lastTime / 1000.0;

	public function width():Float return canvas.width;

	public function height():Float return canvas.height;
}
