package arcane.signal;

interface ISignalDispatcher {
	public function listen(name:String, cb:Signal -> Void):Void;
	public function dispatch(s:Signal):Void;
}
