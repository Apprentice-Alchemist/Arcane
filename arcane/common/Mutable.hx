package arcane.common;

@:generic
class Mutable<T> extends arcane.signal.SignalDispatcher {
	private var value:Null<T>;
	private var getFunc:Void->T;

	public function get():Null<T>
		return getFunc();

	public function set(v:Null<T>):Null<T> {
		value = v;
		dispatch(new arcane.signal.Signal<T>("update", v));
		return v;
	}

	public override function new(?v:T, ?getFunc:Void->Null<T>) {
		if (v != null) value = v;
		if (getFunc != null) this.getFunc = getFunc
		else this.getFunc = () -> value;
		super();
	}
}
