package arcane;

import arcane.spec.ISystem;
import arcane.spec.IGraphicsDriver;
import arcane.spec.IAudioDriver;
import arcane.signal.Signal;
import arcane.signal.SignalDispatcher;
import arcane.common.Version;

@:nullSafety
@:allow(arcane.internal)
class Lib {
	public static var version(default, never):Version = new Version("0.0.1");
	public static var fps(default, null):Float = 0.0;
	public static var dispatcher(default, null):SignalDispatcher = new SignalDispatcher();

	public static var backend(default, null):Null<ISystem>;
	public static var gdriver(default, null):Null<IGraphicsDriver>;
	public static var adriver(default, null):Null<IAudioDriver>;

	private static var init_done:Bool = false;

	#if target.threaded
	private static var mainThread:sys.thread.Thread = cast null;
	#end

	/**
	 * Initialize engine, create the initial window and graphics driver.
	 * Behaviour of methods in this class (and other classes) is undefined before this function is called.
	 * @param cb
	 */
	public static function init(cb:Void->Void):Void {
		#if target.threaded
		mainThread = sys.thread.Thread.current();
		#end
		if (backend == null)
			#if kinc
			backend = new backend.kinc.System();
			#elseif js
			backend = new backend.html5.System();
			#else
			backend = new backend.empty.System();
			#end
		initCb = cb;
		backend.init(cast {}, onInit);
	}

	private static dynamic function initCb():Void {}

	static function onInit():Void {
		init_done = true;
		if (backend == null)
			return;
		if (backend.isFeatureSupported(Graphics3D))
			gdriver = backend.createGraphicsDriver();
		if (backend.isFeatureSupported(Audio))
			adriver = backend.createAudioDriver();
		initCb();
	}

	static function update(dt:Float):Void {
		fps = 1 / (dt);
		// Ensure haxe.Timer
		#if ((target.threaded && !cppia) && haxe_ver >= 4.2)
		mainThread.events.progress();
		#else // MainLoop.tick() is automatically called by the main thread's event loop.
		@:privateAccess haxe.MainLoop.tick();
		#end
		for (o in __updates)
			o(dt);
		if (gdriver != null)
			gdriver.present();
	}

	public static function time():Float return backend == null ? 0 : backend.time();

	private static var __updates = new Array<Float->Void>();

	/**
	 * The passed function will be called every time Lib.update is called by the backend.
	 * 
	 * dt is in seconds.
	 */
	public static function addUpdate(cb:(dt:Float) -> Void):Void {
		__updates.push(cb);
	}

	/**
	 * Removes the passed function from the update list.
	 */
	public static function removeUpdate(cb:Float->Void):Void {
		__updates.remove(cb);
	}

	/**
	 * Execute the appropriate shutdown procedures, and exit the application.
	 * @param code Exit code
	 */
	public static function exit(code:Int):Void {
		if (gdriver != null)
			gdriver.dispose();
		if (backend != null)
			backend.shutdown();
		#if sys
		Sys.exit(code);
		#end
	}
}