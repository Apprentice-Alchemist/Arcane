package arcane.common;

class Mutable<T> extends arcane.signal.SignalDispatcher {
	@:noCompletion private var value:T;

	public function get()
		return value;

	public function set(v:T) {
		value = v;
		dispatch(new Signal("update"));
    };
    override public function new() {
        super(this);
    }
}