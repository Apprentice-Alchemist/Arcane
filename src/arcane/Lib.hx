package arcane;

import arcane.system.IAudioDriver;
import arcane.util.Version;
import arcane.internal.System;
import arcane.system.ISystem;
import arcane.system.IGraphicsDriver;
import arcane.util.Event;

@:nullSafety(Strict)
@:allow(arcane.internal)
#if debug
@:expose("arcane.Lib")
#end
class Lib {
	public static var version(default, never):Version = arcane.internal.Macros.getVersion();
	public static var fps(default, null):Float = 0.0;

	public static var system(default, null):ISystem = new arcane.internal.System();
	public static var gdriver(default, null):Null<IGraphicsDriver>;
	public static var adriver(default, null):Null<IAudioDriver>;

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
		system.init({
			windowOptions: {
				x: -1,
				y: -1,
				width: 500,
				height: 500,
				title: "",
				vsync: true,
				mode: Windowed
			}
		}, () -> {
			gdriver = system.getGraphicsDriver();
			adriver = system.getAudioDriver();
			cb();
		});
	}

	#if (arcane_event_loop_array && !eval)
	static var __event_loop_arr:Array<() -> Void> = [];
	#end

	/**
	 * Handle update stuff.
	 * @param dt Delta t in seconds.
	 */
	static function handle_update(dt:Float):Void {
		fps = 1 / (dt);
		// Ensure haxe.Timer works
		#if !js
		#if ((target.threaded && !cppia) && haxe >= version("4.2.0"))
		// MainLoop.tick() is automatically called by the main thread's event loop.
		#if (arcane_event_loop_array && !eval)
		// @:nullSafety(Off) because __progress is inline and certain parts of it make null safety angry.
		@:privateAccess @:nullSafety(Off) mainThread.events.__progress(Sys.time(), []);
		#else
		mainThread.events.progress();
		#end
		#else
		@:privateAccess haxe.MainLoop.tick();
		#end
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
		#if hl_hot_reload
		hot_reload();
		#end
	}

	#if hl_hot_reload
	@:hlNative("std", "sys_check_reload") static function hot_reload():Bool {
		return false;
	}
	#end

	public static function time():Float {
		return system == null ? 0 : system.time();
	}

	public static final update = new arcane.util.Event<(dt:Float) -> Void>();
	public static final onEvent = new arcane.util.Event<arcane.system.Event>();

	/**
	 * Execute the appropriate shutdown procedures, and exit the application.
	 * @param code Exit code
	 */
	public static function exit(code:Int):Void {
		if (gdriver != null)
			gdriver.dispose();
		if (system != null)
			system.shutdown();
		#if hl_profile
		hl.Profile.dump();
		#end
		#if sys
		Sys.exit(code);
		#end
	}
}
