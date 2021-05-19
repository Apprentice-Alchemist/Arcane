package arcane.system;

interface IAudioBuffer {
	// var data:haxe.io.Bytes;
	var samples:Int;
	var sampleRate:Int;
	var channels:Int;
	function dispose():Void;
}

interface IAudioSource {
	// function play():Void;
	// function stop():Void;
	// var volume(get,set):Void;
	// var pitch(get,set):Void;
	function dispose():Void;
}

interface IAudioDriver {
	// function formatSupported(format:AudioFormat):Bool;
	// function decode(bytes:haxe.io.Bytes):IAudioBuffer;
	function fromFile(path:String, cb:IAudioBuffer->Void):Void;
	function play(buffer:IAudioBuffer, volume:Float, pitch:Float, loop:Bool):IAudioSource;
	function stop(s:IAudioSource):Void;
}
