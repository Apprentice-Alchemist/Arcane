package arcane.internal.empty;

import arcane.system.IAudioDriver;
import arcane.system.IAudioDriver.IAudioSource;
import arcane.system.IAudioDriver.IAudioBuffer;
import arcane.util.Result;

class AudioBuffer implements IAudioBuffer {
	public var samples:Int = 0;
	public var sampleRate:Int = 0;
	public var channels:Int = 0;

	public function new() {}

	public function dispose():Void {}
}

class AudioSource implements IAudioSource {
	public function new() {}

	public function dispose():Void {}
}

class AudioDriver implements IAudioDriver {
	public function new() {}

	public function fromFile(path:String, cb:Result<IAudioBuffer, Any>->Void):Void {}

	public function play(buffer:IAudioBuffer, volume:Float, pitch:Float, loop:Bool):IAudioSource {
		return new AudioSource();
	}

	public function getVolume(source:IAudioSource):Float {
		return 0.0;
	}

	public function setVolume(source:IAudioSource, v:Float):Void {}

	public function stop(s:IAudioSource):Void {}
}
