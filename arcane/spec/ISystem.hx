package arcane.spec;

enum SystemFeature {
	Graphics3D;
	Audio;
}

interface ISystem {
	public function isFeatureSupported(e:SystemFeature):Bool;
	public function init(cb:Void->Void):Void;
	public function shutdown():Void;
	public function createAudioDriver():Null<IAudioDriver>;
	public function createGraphicsDriver():Null<IGraphicsDriver>;
}
