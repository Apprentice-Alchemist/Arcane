package arcane.system;

import haxe.io.Bytes;

typedef SystemOptions = {
	var window_options:WindowOptions;
}

typedef WindowOptions = {
	var x:Int;
	var y:Int;
	var width:Int;
	var height:Int;
	var title:String;
	var vsync:Bool;
	var mode:WindowMode;
}

enum WindowMode {
	Windowed;
	Fullscreen;

	/**
	 * Some windows things.
	 */
	FullscreenExclusive;
}

typedef GraphicsDriverOptions = {}

interface ISystem {
	var window(default, null):IWindow;

	function init(options:SystemOptions, cb:Void->Void):Void;
	function shutdown():Void;
	function createAudioDriver():Null<IAudioDriver>;
	function createGraphicsDriver(?options:GraphicsDriverOptions):Null<IGraphicsDriver>;
	function language():String;
	function time():Float;
	function width():Int;
	function height():Int;

	function lockMouse():Void;
	function unlockMouse():Void;
	function canLockMouse():Bool;
	function isMouseLocked():Bool;

	function showMouse():Void;
	function hideMouse():Void;

	function readFile(path:String, cb:(b:Bytes) -> Void, err:(e:arcane.Assets.AssetError) -> Void):Void;
	function readSavefile(name:String, cb:(Bytes) -> Void, err:() -> Void):Void;
	function writeSavefile(name:String, bytes:Bytes, ?complete:(success:Bool) -> Void):Void;
}

interface IWindow {
	var title(get, set):String;
	var x(get, never):Int;
	var y(get, never):Int;
	var width(get, never):Int;
	var height(get, never):Int;
	var vsync(get, never):Bool;
	var mode(get, set):WindowMode;

	function move(x:Int, y:Int):Void;
	function resize(width:Int, height:Int):Void;
}
