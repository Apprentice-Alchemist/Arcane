package arcane.common;

import haxe.Constraints.Function;
import arcane.signal.*;

class Mutable<T> extends arcane.signal.SignalDispatcher {
	@:noCompletion private var value:T;
	@:noCompletion private var getFunc:Null<Function> = null;
	public function get():Null<T>
		return getFunc == null ? value : getFunc();

	public function set(v:Null<T>):Null<T> {
		value = v;
		dispatch(new Signal("update"));
		return v;
	};

	override public function new<C:T>(?v:C,?getFunc:Null<Function>) {
		if (v != null)
			value = v;
		if(getFunc != null)
			this.getFunc = getFunc;
		super(this);
	}
}
