package arcane;

import haxe.Constraints.Function;
import arcane.adv.sound.SoundHandler;
import arcane.adv.*;
import arcane.controls.Controls;

@:allow(hxd.App)
class Engine {
    
	public static final version:String = haxe.macro.Compiler.getDefine("arcane");
	public static var app(default, null):arcane.adv.App;
	public static var physics(default, null) = null;
	public static var sound(default, null):SoundHandler;

	@:noCompletion static function __init(_app:arcane.adv.App) {
		app = _app;
		sound = new SoundHandler();
		#if debug
		trace(version);
		#end
	}

	public static function addUpdate(cb:Float->Void) {
		app.__updates.push(cb);
	}

	public static function removeUpdate(cb:Float->Void) {
		if (app.__updates.indexOf(cb) > -1)
			app.__updates.remove(cb);
	}
}
