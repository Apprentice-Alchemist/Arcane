package arcane.internal;

import arcane.spec.IAudioDriver;
import arcane.spec.IGraphicsDriver;
import arcane.spec.ISystem;

@:access(arcane)
class System implements ISystem {
	public function isFeatureSupported(f:SystemFeature):Bool
		return switch f {
			case Graphics3D: true;
			case Audio: true;
		}

	public function new() {}

	public function init(opts, cb:Void->Void):Void try {
		kinc.System.init("", 500, 500);
		kinc.System.setUpdateCallback(update);
		kinc.System.setShutdownCallback(function() {
			arcane.Lib.exit(0);
		});
		cb();
		kinc.System.start();
	} catch (e) {
		trace(e.details());
		Sys.exit(-1);
	}

	private var lastTime = 0.0;

	public function update() try {
		var curtime = kinc.System.time();
		arcane.Lib.update(curtime - lastTime);
		lastTime = curtime;
		kinc.g4.Graphics4.swapBuffers();
	} catch (e)
		trace(e.details());

	public function shutdown()
		kinc.System.stop();

	public function createAudioDriver():Null<IAudioDriver>
		return null;

	public function createGraphicsDriver():Null<IGraphicsDriver>
		return new GraphicsDriver();

	public function language():String
		return kinc.System.language();

	public function time():Float
		return kinc.System.time();

	public function width():Float
		return kinc.System.width();

	public function height():Float
		return kinc.System.height();
}
