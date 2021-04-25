package arcane.internal;

import arcane.system.IGraphicsDriver;
import arcane.system.ISystem;

#if js
typedef System = HTML5System;
typedef GraphicsDriver = WebGLDriver;
#elseif (hl && kinc)
typedef System = KincSystem;
typedef GraphicsDriver = KincDriver;
#else
typedef GraphicsDriver = IGraphicsDriver;

class System implements ISystem {
	public function new() {}

	public function init(opts, cb:Void->Void):Void {
		cb();
		var stamp = haxe.Timer.stamp();
		while (true) {
			if (sd)
				break;
			var dt = haxe.Timer.stamp() - stamp;
			stamp += dt;
			arcane.Lib.update(dt);
		}
	}

	private var sd = false;

	public function shutdown():Void {
		sd = true;
	}

	// public function createAudioDriver():Null<IAudioDriver> {
	// 	return null;
	// }

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
#end
