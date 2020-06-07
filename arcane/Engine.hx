package arcane;

import haxe.Constraints.Function;
import arcane.adv.sound.SoundHandler;
import arcane.adv.*;
import arcane.controls.Controls;

@:allow(arcane.adv.App)
class Engine {
	public static final version:String = haxe.macro.Compiler.getDefine("arcane");
	public static var app(default, null):App;
	public static var physics(default, null) = new arcane.physics.Physics();
	public static var sound(default, null):SoundHandler = new SoundHandler();

	@:noCompletion static function __init(_app:App) {
		app = _app;
		sound = new SoundHandler();
		#if debug
		trace(version);
		#end
	}

	public static function addUpdate(cb:Float->Void)
		app.__updates.push(cb);

	public static function removeUpdate(cb:Float->Void)
		app.__updates.remove(cb);

	public static function closeConsole() #if hl return hl.UI.closeConsole(); #else return; #end
}
