package arcane;

import haxe.Constraints.Function;
import arcane.adv.sound.SoundHandler;
import arcane.adv.*;
import arcane.controls.Controls;
import arcane.*;
import arcane.physics.*;

@:allow(arcane.adv.App)
class Engine {
	public static final version:String = haxe.macro.Compiler.getDefine("arcane");
	public static var app(default, null):App;
	public static var physics(default, null) = new Physics();
	public static var sound(default, null) = new SoundHandler();

	@:noCompletion private static function init(_app:App) {
		app = _app;
		
	}

	public static function addUpdate(cb:Float->Void)
		app.__updates.push(cb);
	

	public static function removeUpdate(cb:Float->Void)
		app.__updates.remove(cb);
}
