package arcane.spec;

enum SystemFeature {
	Graphics3D;
	Audio;
}

typedef SystemOptions = {
	var width:Int;
	var height:Int;
	var windowX:Int;
	var windowY:Int;
	var windowTitle:String;
	var ?html5:{
		var ?canvas_id:String;
	}
}

interface ISystem {
	public function isFeatureSupported(e:SystemFeature):Bool;
	public function init(options:SystemOptions, cb:Void->Void):Void;
	public function shutdown():Void;
	public function createAudioDriver():Null<IAudioDriver>;
	public function createGraphicsDriver():Null<IGraphicsDriver>;
	public function language():String;
	public function time():Float;
	public function width():Float;
	public function height():Float;
}
