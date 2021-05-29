package arcane;

import arcane.system.IAudioDriver;
import arcane.common.Version;
import arcane.signal.SignalDispatcher;
import arcane.internal.System;
import arcane.system.ISystem;
import arcane.system.IGraphicsDriver;
import arcane.common.Event;

@:nullSafety(Strict)
@:allow(arcane.internal)
class Lib {
	public static var version(default, never):Version = new Version("0.0.1");
	public static var fps(default, null):Float = 0.0;

	// public static var dispatcher(default, null):SignalDispatcher = new SignalDispatcher();
	public static var backend(default, null):Null<ISystem>;
	public static var gdriver(default, null):Null<IGraphicsDriver>;
	public static var adriver(default, null):Null<IAudioDriver>;

	public static final input = {
		keyDown: new Event<Int>(),
		keyUp: new Event<Int>(),
		mouseDown: new Event(),
		mouseUp: new Event(),
		mouseScroll: new Event<Float>()
	}

	#if target.threaded
	@:nullSafety(Off)
	private static var mainThread:sys.thread.Thread;
	#end

	/**
	 * Initialize engine, create the initial window and graphics driver.
	 * Behaviour of methods in this class (and other classes) is undefined before this function is called.
	 * @param cb
	 */
	public static function init(cb:() -> Void):Void {
		#if target.threaded
		mainThread = sys.thread.Thread.current();
		#end
		var backend = new arcane.internal.System();

		backend.init({
			window_options: {
				x: -1,
				y: -1,
				width: 500,
				height: 500,
				title: "",
				vsync: true,
				mode: Windowed
			}
		}, () -> {
			gdriver = backend.createGraphicsDriver();
			adriver = backend.createAudioDriver();
			arcane.Lib.backend = backend;
			cb();
		});
	}

	#if (arcane_event_loop_array&&!eval)
	static var __event_loop_arr:Array<() -> Void> = [];
	#end

	/**
	 * Handle update stuff.
	 * @param dt Delta t in seconds.
	 */
	static function handle_update(dt:Float):Void {
		fps = 1 / (dt);
		// Ensure haxe.Timer works
		#if ((target.threaded && !cppia) && haxe >= version("4.2.0"))
		// MainLoop.tick() is automatically called by the main thread's event loop.
		#if (arcane_event_loop_array && !eval)
		// @:nullSafety(Off) because __progress is inline and certain parts of it make null safety angry.
		@:privateAccess @:nullSafety(Off) mainThread.events.__progress(Sys.time(), __event_loop_arr);
		#else
		mainThread.events.progress();
		#end
		#else
		@:privateAccess haxe.MainLoop.tick();
		#end
		update.trigger(dt);
		#if hl_profile
		hl.Profile.event(-1); // pause
		#end
		if (gdriver != null) {
			gdriver.present();
		}
		#if hl_profile
		hl.Profile.event(0); // next frame
		hl.Profile.event(-2); // resume
		#end
	}

	public static function time():Float {
		return backend == null ? 0 : backend.time();
	}

	public static final update = new arcane.common.Event<(dt:Float) -> Void>();
	public static final onEvent = new arcane.common.Event<arcane.system.Event>();

	/**
	 * Execute the appropriate shutdown procedures, and exit the application.
	 * @param code Exit code
	 */
	public static function exit(code:Int):Void {
		if (gdriver != null)
			gdriver.dispose();
		if (backend != null)
			backend.shutdown();
		#if hl_profile
		hl.Profile.dump();
		#end
		#if sys
		Sys.exit(code);
		#end
	}
}
