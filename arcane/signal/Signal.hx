package arcane.signal;

/**
 * A basic signal
 */
class Signal {
	/**
	 * Should be obvious
	 */
	public var name:String;

	/**
	 * Wether the signal has been cancelled
	 */
	public var cancelled(default, null):Bool = false;

	/**
	 * The dispatcher that sent the signal
	 */
	public final target:Null<T> = null;

	public inline function new(name:String) {
		this.name = name;
	}

	/**
	 * Cancels the signal, so that it won't be propagated further
	 */
	public inline function cancel() {
		cancelled = true;
	}
}
