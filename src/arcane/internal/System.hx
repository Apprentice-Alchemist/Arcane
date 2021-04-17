package arcane.internal;

import arcane.spec.IAudioDriver;
import arcane.spec.IGraphicsDriver;
import arcane.spec.ISystem;

class System implements ISystem {
	public function isFeatureSupported(f:SystemFeature):Bool return false;

	public function new() {}

	public function init(opts, cb:Void->Void):Void {
		cb();
		var stamp = haxe.Timer.stamp();
		while (true) {
			var t = haxe.Timer.stamp();
			arcane.Lib.update(t - stamp);
			stamp = t;
			if (sd)
				break;
		}
	}

	private var sd = false;

	public function shutdown():Void {
		sd = true;
	}

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

	public function width():Int {
		return 0;
	}

	public function height():Int {
		return 0;
	}
}
