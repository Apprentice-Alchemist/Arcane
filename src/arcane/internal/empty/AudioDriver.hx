package arcane.internal.empty;

import arcane.system.IAudioDriver.IAudioSource;
import arcane.system.IAudioDriver.IAudioBuffer;
import arcane.util.Result;

class AudioBuffer implements IAudioBuffer {
	public var samples:Int;
	public var sampleRate:Int;
	public var channels:Int;

	public function new() {}

	public function dispose():Void {}
}

class AudioSource implements IAudioSource {
	public function new() {}

	public function dispose():Void {}
}

class IAudioDriver {
	function fromFile(path:String, cb:Result<IAudioBuffer, Any>->Void):Void {}

	function play(buffer:IAudioBuffer, volume:Float, pitch:Float, loop:Bool):IAudioSource {
		return null;
	}

	function getVolume(source:IAudioSource):Float {
		return 0.0;
	}

	function setVolume(source:IAudioSource, v:Float):Void {}

	function stop(s:IAudioSource):Void {}
}
