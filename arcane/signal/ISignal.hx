package arcane.signal;

interface ISignal {
	public var name:String;
	public var cancelled(default, null):Bool;
	public var target:Dynamic;
	public function cancel():Void;
}