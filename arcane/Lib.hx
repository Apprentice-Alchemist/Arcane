package arcane;

import arcane.signal.Signal;
import arcane.signal.SignalDispatcher;
import arcane.common.Version;

@:allow(arcane.internal)
class Lib {
	public static var version(default, never):Version = new Version("0.0.1");
	public static var fps(default, null):Float;
	public static var dispatcher(default, null):SignalDispatcher = new SignalDispatcher();
	public static var state(default, set):IState;
	#if heaps
	public static var audio(default, null):arcane.audio.Audio;
	public static var engine(get, null):h3d.Engine;
	public static var s2d(get, null):h2d.Scene;
	public static var s3d(get, null):h3d.scene.Scene;
	public static var sevents(get, null):hxd.SceneEvents;
	private static var app:arcane.internal.App;
	#end

	static function set_state(s:IState):IState
		return null;

	public static function init(cb:Null<Void->Void>):Void {
		initCb = cb;
		#if heaps
		Lib.app = new arcane.internal.App();
		#end
	}

	private static dynamic function initCb():Void {}

	static function onInit():Void {
		#if heaps
		audio = new arcane.audio.Audio();
		#end
		initCb();
	}

	static function update(dt:Float):Void {
		fps = 1 / (dt * 1000);
		for (o in __updates)
			o(dt);
	}

	static function onResize():Void {
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

	#if heaps
	private static inline function get_engine():h3d.Engine
		return app == null ? (h3d.Engine.getCurrent() == null ? null : h3d.Engine.getCurrent()) : app.engine;

	private inline static function get_s2d():h2d.Scene
		return app == null ? null : app.s2d;

	private inline static function get_s3d():h3d.scene.Scene
		return app == null ? null : app.s3d;

	private inline static function get_sevents():hxd.SceneEvents
		return app == null ? null : app.sevents;
	#end
}
