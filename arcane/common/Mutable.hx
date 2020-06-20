package arcane.common;

import arcane.signal.*;

class Mutable<T> extends arcane.signal.SignalDispatcher {
	@:noCompletion private var value:T;

	public function get():Null<T>
		return value;

	public function set(v:Null<T>):Null<T> {
		value = v;
		dispatch(new Signal("update"));
		return v;
	};

	override public function new<C:T>(?v:C) {
		if (v != null)
			value = v;
		super(this);
	}
}
