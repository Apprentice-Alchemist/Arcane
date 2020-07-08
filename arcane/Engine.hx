package arcane;

import haxe.Constraints.Function;
import arcane.adv.sound.SoundHandler;
import arcane.adv.*;
import arcane.controls.Controls;
import arcane.*;
import arcane.physics.*;

@:allow(arcane.App)
class Engine {
	public static final version:String = haxe.macro.Compiler.getDefine("arcane");
	public static var app(default, null):App;
	public static var fps(get, never):Float;
	public static var wantedFps(default, set):Float;

	static function get_fps() {
		#if heaps
		return hxd.Timer.fps();
		#end
		return 10;
	}

	static function set_wantedFps(f:Float):Float {
		#if heaps
		return hxd.Timer.wantedFPS = wantedFps = f;
		#end
		return (wantedFps = 10);
	}

	// public static var physics(default, null) #if heaps = new Physics() #else null #end;
	// public static var sound(default, null) = new SoundHandler();

	@:noCompletion private static function init(_app:App) {
		app = _app;
		// hxd.Timer.
	}

	public static function addUpdate(cb:Float->Void)
		app.__updates.push(cb);

	public static function removeUpdate(cb:Float->Void)
		app.__updates.remove(cb);
}
