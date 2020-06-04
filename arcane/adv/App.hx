package arcane.adv;

import arcane.signal.*;

@:allow(arcane.Engine)
class App extends hxd.App implements ISignalDispatcher {
	override function new() {
		__dispatcher = new SignalDispatcher(this);
		super();
	}
	@:noCompletion final __updates:Array<Float -> Void> = [];
	override function update(dt:Float) {
		for( u in __updates) u(dt);
	}
	override function onResize() dispatch(new Signal("resize"));

	@:noCompletion var __dispatcher:SignalDispatcher;

	public function dispatch(s:Signal):Void
		return __dispatcher.dispatch(s);

	public function listen(name:String, cb:Signal -> Void):Void
		return __dispatcher.listen(name, cb);

	public function hasListener(name):Bool
		return __dispatcher.hasListener(name);
	public function removeListener(cb:Signal -> Void):Void
		return __dispatcher.removeListener(cb);
}
