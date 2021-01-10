package arcane.backend.html5;

import js.html.DOMError;
import arcane.spec.IGraphicsDriver;
import arcane.spec.IAudioDriver;
import arcane.spec.ISystem;

@:access(arcane)
class System implements ISystem {
	public function isFeatureSupported(f:SystemFeature):Bool
		return switch f {
			case Graphics3D: true;
			case Audio: true;
		}

	public function new() {}

	public var canvas:js.html.CanvasElement;

	public function init(opts, cb:Void->Void):Void try {
		var cdef = haxe.macro.Compiler.getDefine("arcane.html5.canvas");
		canvas = cast js.Browser.window.document.getElementById((cdef == "1" || cdef == null) ? "arcane" : cdef);
		cb();
		js.Browser.window.requestAnimationFrame(update);
	} catch (e:haxe.Exception)
		js.Browser.window.alert(e.details());

	private var lastTime = 0.0;

	public function update(dt:Float) try {
		arcane.Lib.update(dt - lastTime);
		lastTime = dt;
		js.Browser.window.requestAnimationFrame(update);
	} catch (e)
		js.Browser.window.alert(e.details());

	public function shutdown() {}

	public function createAudioDriver():Null<IAudioDriver>
		return null;

	public function createGraphicsDriver():Null<IGraphicsDriver> {
		var gl = canvas.getContextWebGL();
		if(gl == null) {
			untyped alert("Could not aquire WebGL context.\n\nYou will now see a blank screen.\n\nPlease make sure you are using a modern browser (recent firefox or chrome will do).");
			return null;
		}
		return new WebGLDriver(gl, canvas);
	}

	public function language():String
		return js.Browser.navigator.language;

	public function time():Float
		return lastTime;
}
