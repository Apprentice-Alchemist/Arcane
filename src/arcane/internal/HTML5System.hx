package arcane.internal;

import arcane.system.Event.KeyCode;
import js.html.WheelEvent;
import js.html.KeyboardEvent;
import js.html.MouseEvent;
import js.html.CanvasElement;
import arcane.system.IGraphicsDriver;
import arcane.system.ISystem;
import js.html.webgl.GL;

@:access(arcane)
class HTML5System implements ISystem {
	public function new() {}

	public var window(default, null):IWindow;
	public var canvas:js.html.CanvasElement;

	public function init(opts:SystemOptions, cb:Void->Void):Void {
		if (!js.Browser.supported)
			throw "expected a browser environment";
		try {
			var cdef = haxe.macro.Compiler.getDefine("arcane.html5.canvas");
			// var cid = (opts != null && opts.html5 != null && opts.html5.canvas_id != null) ? opts.html5.canvas_id : ((cdef == "1" || cdef == null) ? "arcane" : cdef);
			var cid = cdef != null ? cdef : "arcane";
			canvas = cast js.Browser.window.document.getElementById(cid);
			if (canvas == null) {
				untyped alert('Could not find canvas with id ${cid}.');
				return;
			}
			inline function event(he:Dynamic, e:arcane.system.Event) {
				Lib.onEvent.trigger(e);
			}
			canvas.onmousedown = (e:MouseEvent) -> event(e, MouseDown(switch e.button {
				case 1: 0;
				case b: b;
			}, e.clientX, e.clientY));
			canvas.onmouseup = (e:MouseEvent) -> event(e, MouseUp(e.button, e.clientX, e.clientY));
			canvas.onmousemove = (e:MouseEvent) -> event(e, MouseMove(e.movementX, e.movementY));
			canvas.onwheel = (e:WheelEvent) -> event(e, MouseWheel(e.deltaY));
			canvas.onblur = () -> event(null, FocusLost);
			canvas.onfocus = () -> event(null, FocusGained);

			canvas.onkeydown = (e:KeyboardEvent) -> {
				var k = keytocode(e);
				e.stopPropagation();
				if (k.char != null) {
					e.preventDefault();
					event(e,KeyPress(k.char));
				}
				if(k.code != null) {
					event(e,KeyDown(k.code));
				}
			}
			canvas.onkeyup = (e:KeyboardEvent) -> {
				var k = keytocode(e);
				e.stopPropagation();
				if (k.code != null) {
					event(e, KeyUp(k.code));
				}
			}
			cb();
			js.Browser.window.requestAnimationFrame(update);
		} catch (e:haxe.Exception) {
			js.Browser.window.alert(e.details());
		}
	}

	inline function keytocode(e:KeyboardEvent):{
		var code:Null<KeyCode>;
		var char:Null<String>;
	} {
		var ret = {
			code: null,
			char: null
		}
		ret.code = switch e.key {
			case "Unidentified": Unknown;
			case "Alt": Alt;
			case "AltGraph": AltGr;
			case "CapsLock": CapsLock;
			case "Control": Control;
			case "Fn": Fn;
			case "FnLock": FnLock;
			case "Meta": Meta;
			case "NumLock": NumLock;
			case "ScrollLock": ScrollLock;
			case "Shift": Shift;
			case "Symbol" | "SymbolLock": Unknown;
			case "Enter": Enter;
			case "Tab": Tab;
			case "ArrowDown" | "Down": Down;
			case "ArrowLeft" | "Left": Left;
			case "ArrowRight" | "Right": Right;
			case "ArrowUp" | "Up": Up;
			case "End": End;
			case "Home": Home;
			case "PageDown": PageDown;
			case "PageUp": PageUp;
			case "Backspace": Backspace;
			case "Clear": Clear;
			case "Copy": null;
			case "CrSelf": null;
			case "Cut": null;
			case "Delete": Delete;
			case "EraseEof": null;
			case "ExSel": null;
			case "Insert": Insert;
			case "Paste": null;
			case "Redo": null;
			case "Undo": null;
			case "Accept": null;
			case "Again": null;
			case "Attn": null;
			case "Cancel": Cancel;
			case "ContextMenu": ContextMenu;
			case "Escape": Escape;
			case "Execute": Execute;
			case "Find": null;
			case "Help": Help;
			case "Pause": Pause;
			case "Play": null;
			case "Props": null;
			case "Select": null;
			case "ZoomIn": null;
			case "ZoomOut": null;

			case "Dead": null;
			// TODO : Asian/Korean keys
			case k if (k.charAt(0) == "F" && Std.parseInt(k.substr(1)) != null):
				F1 + Std.parseInt(k.substr(1)) - 1;
			case k if (StringTools.startsWith(k, "Soft")): null;
			case "ChannelDown" | "ChannelUp" | "Close": null;
			case k if (StringTools.startsWith(k, "Mail")): null;
			case k if (StringTools.startsWith(k, "Media")): null;
			case "New" | "Open" | "Print" | "Save" | "SpellCheck": null;
			case "Key11" | "Key12": null;
			case k if (StringTools.startsWith(k, "Audio")): null;
			case k if (StringTools.startsWith(k, "Microphone")): null;
			case k if (StringTools.startsWith(k, "Speech")): null;
			case k if (StringTools.startsWith(k, "Launch")): null;
			case k if (StringTools.startsWith(k, "Browser")): null;
			// a whole load of other keys
			case k: {
					ret.char = k;
					switch k {
						case k if (k >= "a" && k <= "z"): A + k.charCodeAt(0) - "a".code;
						case k if (k >= "A" && k <= "A"): A + k.charCodeAt(0) - "a".code;
						case k if (k >= "0" && k <= "9"):
							if (e.location == KeyboardEvent.DOM_KEY_LOCATION_NUMPAD)
								Numpad0 + k.charCodeAt(0) - "0".code; else Number0 + k.charCodeAt(0) - "0".code;
						case ",": Comma;
						case ";": SemiColon;
						case ":": Colon;
						case "!": Exclaim;
						case "*": Multiply;
						case "+": Plus;
						case "-": Minus;
						case "/": Slash;
						case "$": Dollar;
						case "&": Ampersand;
						case '"': DoubleQuote;
						case "'": Quote;
						case "(": LeftParen;
						case ")": RightParen;
						case "_": Underscore;
						case "\\": Backslash;
						case "=": Equals;
						case ">": GreaterThan;
						case "<": LessThan;
						case "?": QuestionMark;
						case ".": Period;
						case " ": Space;
						case _: Unknown;
					}
				};
		}
		return ret;
	}

	private var lastTime = 0.0;

	public function update(dt:Float) {
		try {
			arcane.Lib.handle_update((dt - lastTime) / 1000);
			lastTime = dt;
			js.Browser.window.requestAnimationFrame(update);
		} catch (e) {
			js.Browser.window.alert(e.details());
		}
	}

	public function shutdown() {}

	public function createAudioDriver():Null<arcane.system.IAudioDriver> {
		return new WebAudioDriver();
	}

	public function createGraphicsDriver(?options:GraphicsDriverOptions):Null<IGraphicsDriver> {
		// final canvas = if(options == null) this.canvas else options.canvas;
		var gl:GL = canvas.getContextWebGL2({alpha: false, antialias: false, stencil: true});
		var wgl2 = true;
		if (gl == null) {
			gl = canvas.getContextWebGL({alpha: false, antialias: false, stencil: true});
			wgl2 = false;
		}
		if (gl == null) {
			untyped alert("Could not aquire WebGL context.");
			return null;
		}
		return new arcane.internal.WebGLDriver(gl, canvas, wgl2);
	}

	public function language():String {
		return js.Browser.navigator.language;
	}

	public function time():Float {
		return lastTime / 1000.0;
	}

	public function width():Int {
		return canvas.width;
	}

	public function height():Int {
		return canvas.height;
	}

	public function lockMouse():Void {
		canvas.requestPointerLock();
	}

	public function unlockMouse():Void {
		js.Browser.document.exitPointerLock();
	}

	public function canLockMouse():Bool {
		return js.Syntax.code("'pointerLockElement' in document ||
		'mozPointerLockElement' in document ||
		'webkitPointerLockElement' in document");
	}

	public function isMouseLocked():Bool {
		return js.Syntax.code("document.pointerLockElement === {0} ||
			document.mozPointerLockElement === {0} ||
			document.webkitPointerLockElement === {0}", this.canvas);
	}

	public function showMouse():Void {}

	public function hideMouse():Void {}
}

private class HTML5Window implements IWindow {
	public var title(get, set):String;
	public var x(get, never):Int;
	public var y(get, never):Int;
	public var width(get, never):Int;
	public var height(get, never):Int;
	public var vsync(get, never):Bool;
	public var mode(get, set):WindowMode;

	var canvas:CanvasElement;

	public function new(canvas) {
		this.canvas = canvas;
	}

	public function get_title():String {
		return js.Browser.window.name;
	}

	public function set_title(value:String):String {
		return js.Browser.window.name = value;
	}

	public function get_x():Int {
		return 0;
	}

	public function get_y():Int {
		return 0;
	}

	public function get_width():Int {
		return canvas.width;
	}

	public function get_height():Int {
		return canvas.width;
	}

	public function get_vsync():Bool {
		return true;
	}

	public function get_mode():WindowMode {
		var doc = js.Browser.document;
		if (doc.fullscreenElement != null) {
			return Fullscreen;
		}

		return Windowed;
	}

	public function set_mode(value:WindowMode):WindowMode {
		var doc = js.Browser.document;
		var fullscreen = value != Windowed;
		if ((doc.fullscreenElement == canvas) == fullscreen)
			return Windowed;
		if (value != Windowed)
			canvas.requestFullscreen();
		else
			doc.exitFullscreen();

		return value;
	}

	public function move(x:Int, y:Int) {}

	public function resize(width:Int, height:Int) {
		canvas.width = width;
		canvas.height = height;
	}
}
