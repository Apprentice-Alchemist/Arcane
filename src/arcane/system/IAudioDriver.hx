package arcane.system;

interface IAudioBuffer {
	var samples:Int;
	var sampleRate:Int;
	var channels:Int;
	function dispose():Void;
}

interface IAudioSource {
	function dispose():Void;
}

interface IAudioDriver {
	function fromFile(path:String, cb:IAudioBuffer->Void):Void;
	function play(buffer:IAudioBuffer, volume:Float, pitch:Float, loop:Bool):IAudioSource;
	function getVolume(source:IAudioSource):Float;
	function setVolume(source:IAudioSource,v:Float):Void;
	function stop(s:IAudioSource):Void;
}