package arcane.internal.empty;

import arcane.system.IAudioDriver;
import arcane.util.Result;

private class AudioBuffer implements IAudioBuffer {
	public var samples:Int = 0;
	public var sampleRate:Int = 0;
	public var channels:Int = 0;

	public function new() {}

	public function dispose():Void {}
}

private class AudioSource implements IAudioSource {
	public function new() {}

	public function dispose():Void {}
}

class EmptyAudioDriver implements IAudioDriver {
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
