package arcane.internal;

import arcane.spec.IAudioDriver;
import arcane.spec.IGraphicsDriver;
import arcane.spec.ISystem;

class System implements ISystem {
	public function isFeatureSupported(f:SystemFeature):Bool return false;

	public function new() {}

	public function init(opts, cb:Void->Void):Void {}

	public function shutdown():Void {}

	public function createAudioDriver():Null<IAudioDriver> {
		return null;
	}

	public function createGraphicsDriver():Null<IGraphicsDriver> {
		return null;
	}

	public function language():String {
		return "";
	}

	public function time():Float {
		return 0.0;
	}

	public function width():Float {
		return 0.0;
	}

	public function height():Float {
		return 0.0;
	}
}
