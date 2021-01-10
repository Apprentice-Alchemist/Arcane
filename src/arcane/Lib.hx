package arcane;

import arcane.spec.ISystem;
import arcane.spec.IGraphicsDriver;
import arcane.spec.IAudioDriver;
import arcane.signal.Signal;
import arcane.signal.SignalDispatcher;
import arcane.common.Version;

@:allow(arcane.internal)
class Lib {
	public static var version(default, never):Version = new Version("0.0.1");
	public static var fps(default, null):Float;
	public static var dispatcher(default, null):SignalDispatcher = new SignalDispatcher();

	private static var backend:Null<ISystem>;
	private static var gdriver:Null<IGraphicsDriver>;
	private static var adriver:Null<IAudioDriver>;
	private static var init_done:Bool = false;

	public static function setBackend(b) {
		if(init_done)
			throw "Switching backends after Lib.init was called is not supported";
		backend = b;
	}

	public static function init(cb:Null<Void->Void>):Void {
		if(backend == null)
			#if kinc
			backend = new arcane.backend.kinc.System();
			#elseif js
			backend = new arcane.backend.html5.System();
			#else
			backend = new arcane.backend.empty.System();
			#end
		initCb = cb;
		backend.init(cast {}, onInit);
	}

	private static dynamic function initCb():Void {}

	static function onInit():Void {
		init_done = true;
		if(backend.isFeatureSupported(Graphics3D))
			gdriver = backend.createGraphicsDriver();
		if(backend.isFeatureSupported(Audio))
			adriver = backend.createAudioDriver();
		initCb();
	}

	static function update(dt:Float):Void {
		if(gdriver != null)
			gdriver.begin();
		fps = 1 / (dt * 1000);
		for (o in __updates)
			o(dt);
		if(gdriver != null)
			gdriver.end();
		if(gdriver != null)
			gdriver.present();
	}

	public static function time():Float return backend.time();

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
	 * Execute the appropriate shutdown procedures, and exit the application.
	 * @param code Exit code
	 */
	public static function exit(code:Int):Void {
		if(gdriver != null)
			gdriver.dispose();
		if(backend != null)
			backend.shutdown();
		#if sys
		Sys.exit(code);
		#end
	}
}
