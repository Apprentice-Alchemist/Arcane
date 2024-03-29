package arcane.internal.html5;

import arcane.audio.IAudioDevice;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import arcane.Assets.AssetError;
import arcane.system.Event.KeyCode;
import js.html.WheelEvent;
import js.html.KeyboardEvent;
import js.html.MouseEvent;
import js.html.CanvasElement;
import arcane.gpu.IGPUDevice;
import arcane.system.ISystem;

@:access(arcane)
@:nullSafety(StrictThreaded)
class HTML5System implements ISystem {
	public var window:IWindow;
	public var canvas:js.html.CanvasElement;
	public var gdriver:Null<IGPUDevice>;
	public var adriver:Null<IAudioDevice>;

	public function new() {
		if (!js.Browser.supported)
			throw "expected a browser environment";
		var cdef = (haxe.macro.Compiler.getDefine("arcane.html5.canvas") : Null<String>);
		if (cdef == null)
			cdef = "arcane";
		canvas = cast js.Browser.window.document.getElementById(cdef);
		if (canvas == null) {
			throw 'Could not find canvas with id ${cdef}.';
		}
		window = new HTML5Window(canvas);
	}

	#if wgpu_externs
	private static var gpuAdapter:Null<wgpu.GPUAdapter>;
	#end

	public function init(opts:SystemOptions, cb:Void->Void):Void {
		inline function event(e:arcane.system.Event) Lib.onEvent.trigger(e);

		canvas.onmousedown = (e:MouseEvent) -> event(MouseDown(switch e.button {
			case 1: 0;
			case b: b;
		}, e.clientX, e.clientY));
		canvas.onmouseup = (e:MouseEvent) -> event(MouseUp(e.button, e.clientX, e.clientY));
		canvas.onmousemove = (e:MouseEvent) -> event(MouseMove(e.movementX, e.movementY));
		canvas.onwheel = (e:WheelEvent) -> event(MouseWheel(e.deltaY));
		canvas.onblur = () -> event(FocusLost);
		canvas.onfocus = () -> event(FocusGained);

		canvas.onkeydown = (e:KeyboardEvent) -> {
			e.stopPropagation();
			var k = keytocode(e);
			var char = k.char;
			var code = k.code;
			if (char != null) {
				event(KeyPress(char));
				e.preventDefault();
			}
			if (code != null) {
				event(KeyDown(code));
			}
		}
		canvas.onkeyup = (e:KeyboardEvent) -> {
			e.stopPropagation();
			var k = keytocode(e);
			var code = k.code;
			if (code != null) {
				event(KeyUp(code));
			}
		}

		#if wgpu_externs
		if (js.Syntax.typeof(untyped navigator.gpu) != "undefined") {
			(untyped navigator.gpu : wgpu.GPU).requestAdapter()
				.then(adapter -> {
					if (adapter != null) {
						gpuAdapter = adapter;
						adapter.requestDevice({
							label: "arcane"
						});
					} else {
						throw "Null adapter.";
					}
				},e -> untyped console.error(e))
				.then(device -> {
					var context = canvas.getContext("webgpu");
					if (context == null)
						context = canvas.getContext("gpupresent");
					if (context == null) {
						js.Browser.console.error("Could not aquire the WebGPU context of the canvas.");
					} else {
						js.Browser.console.info("Using WebGPU.");
						gdriver = new WGPUDriver(canvas, context, cast gpuAdapter, device);
					}
				})
				.catchError(e -> {
					js.Browser.console.error("Could not aquire a WebGPU context.", e);
				})
				.then(_ -> {
					cb();
					js.Browser.window.requestAnimationFrame(update);
					return;
				})
				.catchError(e -> untyped console.error(e));
		} else {
		#end
			var gl = canvas.getContextWebGL2({alpha: false, antialias: false, stencil: true});
			if (gl != null) {
				js.Browser.console.log("Using WebGL 2.");
				gdriver = new WebGL2Driver(gl, canvas);
			} else
				js.Browser.console.error("Could not aquire WebGL 2 context.");

			cb();
			js.Browser.window.requestAnimationFrame(update);
		#if wgpu_externs
		}
		#end
	}

	@:nullSafety(Off) inline function keytocode(e:KeyboardEvent):{
		var code:Null<KeyCode>;
		var char:Null<String>;
	}
		@:nullSafety(Off) {
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
			case "Clear": KeyCode.Clear;
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
				F1 + (cast Std.parseInt(k.substr(1)) : Int) - 1;
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
			(untyped console).error(e.details());
		}
	}

	public function shutdown() {}

	public function getAudioDevice():Null<IAudioDevice> {
		return new WebAudioDriver();
	}

	public function getGPUDevice():Null<IGPUDevice> {
		return gdriver;
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

	public function readFile(path:String, cb:(b:Bytes) -> Void, err:(e:AssetError) -> Void) {
		js.Browser.window.fetch(path).then(response -> {
			if (response.ok) {
				response.arrayBuffer().then(b -> cb(Bytes.ofData(b))).catchError(e -> err(Other(path, Std.string(e))));
			} else if (response.status == 404) {
				err(NotFound(path));
			} else {
				err(Other(path, response.statusText));
			}
		}).catchError(e -> err(Other(path, Std.string(e))));
	}

	public function readSavefile(name:String, cb:Bytes->Void, err:(e:AssetError) -> Void) {
		var storage = js.Browser.getLocalStorage();
		if (storage != null)
			try {
				final item = storage.getItem(name);
				if (item == null)
					err(NotFound(name));
				else
					cb(Base64.decode(item));
			} catch (e)
				err(NotFound(name));
		else
			err(Other("localStorage is unsupported or disabled."));
	}

	public function writeSavefile(name:String, bytes:Bytes, ?complete:(success:Bool) -> Void) {
		var storage = js.Browser.getLocalStorage();
		if (storage != null)
			try {
				storage.setItem(name, Base64.encode(bytes));
				if (complete != null)
					complete(true);
			} catch (e) {
				if (complete != null)
					complete(false);
			}
		else if (complete != null)
			complete(false);
	}
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
		switch value {
			case Windowed if (doc.fullscreenElement == canvas):
				doc.exitFullscreen();
			case Fullscreen | FullscreenExclusive if (doc.fullscreenElement != canvas):
				canvas.requestFullscreen();
			case _:
		}
		return value;
	}

	public function move(x:Int, y:Int) {}

	public function resize(width:Int, height:Int) {
		canvas.width = width;
		canvas.height = height;
	}
}
