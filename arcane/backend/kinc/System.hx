package arcane.backend.kinc;

import arcane.spec.ISystem.SystemFeature;
import arcane.spec.*;

@:access(arcane)
class System implements ISystem {
	public function isFeatureSupported(f:SystemFeature):Bool
		return switch f {
			case Graphics3D: true;
			case Audio: true;
		}

	public function new() {}

	public function init(cb:Void->Void):Void {
		kinc.System.init("", 500, 500);
		kinc.System.setUpdateCallback(update);
		cb();
		kinc.System.start();
	}
	private var lastTime = 0.0;
	public function update(){
		var curtime = kinc.System.time();
		arcane.Lib.update(curtime - lastTime);
		lastTime = curtime;
	}

	public function shutdown()
		kinc.System.stop();

	public function createAudioDriver():Null<IAudioDriver>
		return null;

	public function createGraphicsDriver():Null<IGraphicsDriver>
		return new GraphicsDriver();
}
