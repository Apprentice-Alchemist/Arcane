package arcane.backend.html5;

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

	var canvas:js.html.CanvasElement;

	public function init(cb:Void->Void):Void {
		canvas = cast js.Browser.window.document.getElementById("webgl");
		cb();
		js.Browser.window.requestAnimationFrame(update);
	}

	private var lastTime = 0.0;

	public function update(dt:Float) {
		arcane.Lib.update(dt - lastTime);
		lastTime = dt;
		js.Browser.window.requestAnimationFrame(update);
	}

	public function shutdown() {}

	public function createAudioDriver():Null<IAudioDriver>
		return null;

	public function createGraphicsDriver():Null<IGraphicsDriver>
		return new WebGLDriver(canvas);
}
