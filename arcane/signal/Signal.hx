package arcane.signal;

/**
 * A basic signal
 */
class Signal {

	public var name:String;

	/**
	 * Wether the signal has been cancelled
	 */
	public var cancelled(default, null):Bool = false;

	/**
	 * The dispatcher that sent the signal
	 */
	public var target = null;

	public function new(name:String) {
		this.name = name;
	}

	/**
	 * Cancels the signal, so that it won't be propagated further
	 */
	public function cancel() {
		cancelled = true;
	}
}
