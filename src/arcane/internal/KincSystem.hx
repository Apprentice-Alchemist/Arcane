package arcane.internal;

import arcane.system.IGraphicsDriver;
import arcane.system.ISystem;

@:access(arcane)
class KincSystem implements ISystem {
	public function new() {}

	public function init(opts, cb:Void->Void):Void {
		try {
			kinc.System.init("", 500, 500);
			kinc.System.setUpdateCallback(update);
			kinc.System.setShutdownCallback(function() {
				arcane.Lib.exit(0);
			});
			kinc.input.Keyboard.setKeyDownCallback(keycode -> {
				arcane.Lib.input.keyDown.trigger(cast keycode);
			});
			kinc.input.Mouse.setScrollCallback((_,delta) -> {
				arcane.Lib.input.mouseScroll.trigger(delta);
			});
			cb();
			kinc.System.start();
		} catch (e) {
			trace(e.details());
			Sys.exit(-1);
		}
	}

	private var lastTime = 0.0;

	public function update() {
		try {
			var curtime = kinc.System.time();
			var dt = curtime - lastTime;
			lastTime = curtime;
			arcane.Lib.update(dt);
			// kinc.g4.Graphics4.swapBuffers();
		} catch (e) {
			trace(e.details());
			kinc.System.stop();
		}
	}

	public function shutdown():Void {
		kinc.System.stop();
	}

	// public function createAudioDriver():Null<IAudioDriver> {
	// 	return null;
	// }

	public function createGraphicsDriver():Null<KincDriver> {
		return new KincDriver();
	}

	public function language():String {
		return kinc.System.language().toString();
	}

	public function time():Float {
		return kinc.System.time();
	}

	public function width():Int {
		return kinc.System.width();
	}

	public function height():Int {
		return kinc.System.height();
	}
}
