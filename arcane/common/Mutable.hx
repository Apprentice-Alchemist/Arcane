package arcane.common;

#if (!display&&target.static)
@:generic
#end
class Mutable<T> extends arcane.signal.SignalDispatcher {
	@:noCompletion private var value:T;
	@:noCompletion private var getFunc:Void->T = null;
	public function get():Null<T>
		return getFunc();

	public function set(v:Null<T>):Null<T> {
		value = v;
		dispatch(new arcane.signal.Signal("update"));
		return v;
	}

	override public function new<C:T>(?v:C,?getFunc:Void->C) {
		if (v != null)
			value = v;
		if(getFunc != null)
			this.getFunc = getFunc;
		else
			this.getFunc = ()->value;
		super(this);
	}
}