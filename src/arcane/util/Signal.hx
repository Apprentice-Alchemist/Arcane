package arcane.util;

/**
 * A basic signal
 */
@:nullSafety
class Signal<V> {
	public var name:String;

	/**
	 * Wether the signal has been cancelled
	 */
	public var cancelled(default, null):Bool = false;

	public var value:Null<V>;
	public var dispatcher:Null<SignalDispatcher>;

	public function new(name:String, ?value:Null<V>) {
		this.name = name;
		this.value = value;
	}

	/**
	 * Cancels the signal, so that it won't be propagated further
	 */
	public function cancel() {
		cancelled = true;
	}
}
