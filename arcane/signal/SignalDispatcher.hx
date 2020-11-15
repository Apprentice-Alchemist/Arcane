package arcane.signal;

@:forward
abstract EventType<T>(String) from String to String {}

class SignalDispatcher {
	@:noCompletion @:noDoc public var eventMap:Map<String, Array<Signal<Dynamic>->Void>> = new Map();

	public function new() {}

	/**
	 * Dispatches a signal
	 * ```haxe
	 * instance.dispatch(new Signal("base"))
	 * ```
	 * @param s the signal you want to send
	 */
	public function dispatch<T>(s:Signal<T>):Void {
		s.dispatcher = this;
		@:privateAccess s.cancelled = false;
		if (eventMap.exists(s.name))
			for (o in eventMap.get(s.name)) {
				if (s.cancelled)
					break;
				o(s);
			}
	}

	/**
		Listen for a signal

		@param name The name of the signal you want to listen for
		@param cb The call back

	**/
	public function listen<T>(name:EventType<T>, cb:Signal<T>->Void):Void {
		if (eventMap.exists(name)) {
			eventMap.get(name).unshift(cast cb);
		} else {
			eventMap.set(name, [cast cb]);
		}
	}

	/**
	 * Removes a listener
	 */
	public function removeListener<T>(name:EventType<T>, cb:Signal<T>->Void):Void {
		if (eventMap.exists(name)) {
			for (o in eventMap.get(name)) {
				if (Reflect.compareMethods(o, cb)) {
					eventMap.get(name).remove(o);
				}
			}
		}
	}

	/**
	 * Checks wether a listener has been registered
	 *
	 * @param name
	 */
	public function hasListener<T>(name:EventType<T>):Bool {
		return eventMap.exists(name) ? eventMap.get(name).length > 0 : false;
	}
}
