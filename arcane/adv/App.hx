package arcane.adv;

import format.abc.Data.ABCData;
import arcane.signal.*;

@:allow(arcane.Engine)
@:access(SignalDispatcher)
class App extends hxd.App {
	override public function new() {
		dispatcher = new SignalDispatcher(this);
		Engine.__init(this);
		super();
	}

	private final __updates:Array<Float->Void> = new Array();

	private override function update(dt:Float) {
		for (u in __updates)
			u(dt);
	}

	private override function onResize() {
		dispatch(new Signal("resize"));
	}

	private var dispatcher:SignalDispatcher;

	public function dispatch(s:Signal):Void
		return dispatcher.dispatch(s);

	public function listen(name:String, cb:Signal->Void):Void
		return dispatcher.listen(name, cb);

	public function hasListener(name):Bool
		return dispatcher.hasListener(name);

	public function removeListener(name:String, cb:Signal->Void):Void
		return dispatcher.removeListener(name, cb);
}
