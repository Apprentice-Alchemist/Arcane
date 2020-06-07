package arcane.signal;

/**
 * A basic signal dispatcher
 */
class SignalDispatcher {
	private var eventMap:Map<String, Array<Signal->Void>>;
	@:noCompletion var __target:Dynamic;

	public function new(?customTarget) {
		eventMap = new Map();
		if (customTarget != null)
			__target = customTarget;
		else
			__target = this;
	}

	/**
	 * Dispatches a signal
	 * ```haxe
	 * instance.dispatch(new Signal("base"))
	 * ```
	 * @param s the signal you want to send
	 */
	public function dispatch(s:Signal) {
		s.target = __target;
		if (eventMap.exists(s.name))
			for (o in eventMap.get(s.name)) {
				if (s.cancelled)
					break;
				o(s);
			}
	}

	/**
		Listen for a signal
		```haxe
		instance.listen("base",on_base)
		```

		@param name The name of the signal you want to listen for

		@param cb The call back

	**/
	public function listen(name:String, cb:Signal->Void) {
		if (eventMap.exists(name)) {
			eventMap.get(name).unshift(cb);
		} else {
			eventMap.set(name, [cb]);
		}
	}

	/**
	 * Removes a listener
	 */
	public function removeListener(name:String, cb:Signal->Void) {
		if (eventMap.exists(name))
			eventMap.get(name).remove(cb);
	}

	/**
	 * Checks wether a listener has been registered
	 * @param name
	 */
	public function hasListener(name:String) {
		return eventMap.exists(name) ? eventMap.get(name).length > 0 : false;
	}
}
