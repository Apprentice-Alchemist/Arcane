package arcane;

import arcane.signal.Signal;
import arcane.signal.SignalDispatcher;
import arcane.audio.Audio;
import arcane.common.Version;

@:allow(arcane.backend)
class Lib {
	public static var fps(default, null):Float;
	public static var dispatcher(default, null):SignalDispatcher = new SignalDispatcher();
	public static var state(default, set):IState;

	static function set_state(s:IState):IState
		return null;

	public static function init() {}

	private static dynamic function initCb() {}

	public static function onInit() {
		initCb();
	}

	static function update(dt:Float) {
		fps = 1 / (dt * 1000);
		for (o in __updates)
			o(dt);
	}

	static function onResize() {
		dispatcher.dispatch(new Signal("resize"));
	}

	private static var __updates:Array<Float->Void> = [];

	/**
	 * The passed callback will be called every time `Lib.update` is called by the backend.
	 * Dt in milliseconds.
	 * @param cb
	 * @return Void
	 */
	public static function addUpdate(cb:Float->Void):Void
		__updates.push(cb);

	public static function removeUpdate(cb:Float->Void):Void
		__updates.remove(cb);

	/**
	 * [Description]
	 * @param code Exit code
	 * @param force Force exit
	 */
	public static function exit(code:Int, force:Bool = false):Void {}
}
