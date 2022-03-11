package arcane.internal.kinc;

import arcane.Assets.AssetError;
import arcane.util.Result;
import arcane.util.ThreadPool;
import haxe.io.Bytes;
import arcane.system.IAudioDriver;
import kinc.input.Mouse;
import arcane.system.IGraphicsDriver;
import arcane.system.ISystem;
import kinc.input.Keyboard.KeyCode as KincCode;
import arcane.system.Event.KeyCode as ArcaneCode;

@:access(arcane)
class KincSystem implements ISystem {
	/**
	 * thread pool for I/O, audio decoding, etc...
	 */
	public var thread_pool:ThreadPool;

	public var window(default, null):IWindow;

	public function new() {
		window = new KincWindow(0, "");
		thread_pool = new ThreadPool(2);
	}

	public function init(opts:SystemOptions, cb:Void->Void):Void {
		try {
			if (kinc.System.init(opts.windowOptions.title, 500, 500, {
				title: opts.windowOptions.title,
				// y: opts.windowOptions.x,
				// x: opts.windowOptions.y,
				window_features: MINIMIZABLE | MAXIMIZABLE | RESIZEABLE,
				width: opts.windowOptions.width,
				height: opts.windowOptions.height,
				visible: true,
				mode: switch opts.windowOptions.mode {
					case Windowed: WINDOWED;
					case Fullscreen: FULLSCREEN;
					case FullscreenExclusive: EXCLUSIVE_FULLSCREEN;
				},
				display_index: 0
			}, {
				vertical_sync: opts.windowOptions.vsync,
				stencil_bits: 8,
				samples_per_pixel: 1,
				frequency: 60,
				depth_bits: 16,
				color_bits: 32
			}) != 0)
				throw "init error";

			kinc.System.setUpdateCallback(update);
			kinc.System.setShutdownCallback(() -> arcane.Lib.exit(0));

			inline function event(e:arcane.system.Event) arcane.Lib.onEvent.trigger(e);

			kinc.input.Keyboard.setKeyDownCallback(key -> event(KeyDown(convertKeycode(key))));
			kinc.input.Keyboard.setKeyUpCallback(key -> event(KeyUp(convertKeycode(key))));
			kinc.input.Keyboard.setKeyPressCallback(code -> event(KeyPress(String.fromCharCode(code))));

			kinc.input.Mouse.setPressCallback((window, button, x, y) -> event(MouseDown(button, x, y)));
			kinc.input.Mouse.setScrollCallback((_, delta) -> event(MouseWheel(delta)));
			kinc.input.Mouse.setReleaseCallback((window, button, x, y) -> event(MouseUp(button, x, y)));
			kinc.input.Mouse.setEnterWindowCallback(window -> event(MouseEnter));
			kinc.input.Mouse.setLeaveWindowCallback(window -> event(MouseLeave));
			kinc.input.Mouse.setMoveCallback((window, x, y, mov_x, mov_y) -> event(MouseMove(mov_x, mov_y)));

			kinc.Window.setResizeCallback(0, (i1, i2) -> event(Resize(i1, i2)));

			kinc.System.setBackgroundCallback(() -> event(FocusLost));
			kinc.System.setForegroundCallback(() -> event(FocusGained));

			cb();
			kinc.System.start();
		} catch (e) {
			trace(e.details());
			Sys.exit(-1);
		}
	}

	inline static function convertKeycode(k:kinc.input.Keyboard.KeyCode):arcane.system.Event.KeyCode {
		return switch k {
			case KEY_UNKNOWN: Unknown;
			case KEY_BACK: Back;
			case KEY_CANCEL: Cancel;
			case KEY_HELP: Help;
			case KEY_BACKSPACE: Backspace;
			case KEY_TAB: Tab;
			case KEY_CLEAR: Clear;
			case KEY_RETURN: Return;
			case KEY_SHIFT: Shift;
			case KEY_CONTROL: Control;
			case KEY_ALT: Alt;
			case KEY_PAUSE: Pause;
			case KEY_CAPS_LOCK: CapsLock;
			// case KEY_KANA:
			// case KEY_HANGUL:
			// case KEY_EISU:
			// case KEY_JUNJA:
			case KEY_FINAL: Final;
			// case KEY_HANJA:
			// case KEY_KANJI:
			case KEY_ESCAPE: Escape;
			case KEY_CONVERT: Convert;
			case KEY_NON_CONVERT: NonConvert;
			case KEY_ACCEPT: Accept;
			case KEY_MODE_CHANGE: ModeChange;
			case KEY_SPACE: Space;
			case KEY_PAGE_UP: PageUp;
			case KEY_PAGE_DOWN: PageDown;
			case KEY_END: End;
			case KEY_HOME: Home;
			case KEY_LEFT: Left;
			case KEY_UP: Up;
			case KEY_RIGHT: Right;
			case KEY_DOWN: Down;
			case KEY_SELECT: Select;
			case KEY_PRINT: Print;
			case KEY_EXECUTE: Execute;
			case KEY_PRINT_SCREEN: PrintScreen;
			case KEY_INSERT: Insert;
			case KEY_DELETE: Delete;
			case KEY_0: Number0;
			case KEY_1: Number1;
			case KEY_2: Number2;
			case KEY_3: Number3;
			case KEY_4: Number4;
			case KEY_5: Number5;
			case KEY_6: Number6;
			case KEY_7: Number7;
			case KEY_8: Number8;
			case KEY_9: Number9;
			case KEY_COLON: Colon;
			case KEY_SEMICOLON: SemiColon;
			case KEY_LESS_THAN: LessThan;
			case KEY_EQUALS: Equals;
			case KEY_GREATER_THAN: GreaterThan;
			case KEY_QUESTIONMARK: QuestionMark;
			case KEY_AT: At;
			case k if ((k : Int) >= (KEY_A : Int) && (k : Int) <= (KEY_Z : Int)):
				(k : Int) - (KEY_A : Int) + (ArcaneCode.A : Int);

			case KEY_WIN: Windows;
			case KEY_CONTEXT_MENU: ContextMenu;
			case KEY_SLEEP: Sleep;
			case KEY_NUMPAD_0: Numpad0;
			case KEY_NUMPAD_1: Numpad1;
			case KEY_NUMPAD_2: Numpad2;
			case KEY_NUMPAD_3: Numpad3;
			case KEY_NUMPAD_4: Numpad4;
			case KEY_NUMPAD_5: Numpad5;
			case KEY_NUMPAD_6: Numpad6;
			case KEY_NUMPAD_7: Numpad7;
			case KEY_NUMPAD_8: Numpad8;
			case KEY_NUMPAD_9: Numpad9;
			case KEY_MULTIPLY: Multiply;
			case KEY_ADD: Add;
			case KEY_SEPARATOR: Separator;
			case KEY_SUBTRACT: Substract;
			case KEY_DECIMAL: Decimal;
			case KEY_DIVIDE: Divide;
			case KEY_F1: F1;
			case KEY_F2: F2;
			case KEY_F3: F3;
			case KEY_F4: F4;
			case KEY_F5: F5;
			case KEY_F6: F6;
			case KEY_F7: F7;
			case KEY_F8: F8;
			case KEY_F9: F9;
			case KEY_F10: F10;
			case KEY_F11: F11;
			case KEY_F12: F12;
			case KEY_F13: F13;
			case KEY_F14: F14;
			case KEY_F15: F15;
			case KEY_F16: F16;
			case KEY_F17: F17;
			case KEY_F18: F18;
			case KEY_F19: F19;
			case KEY_F20: F20;
			case KEY_F21: F21;
			case KEY_F22: F22;
			case KEY_F23: F23;
			case KEY_F24: F24;
			case KEY_NUM_LOCK: NumLock;
			case KEY_SCROLL_LOCK: ScrollLock;
			// case KEY_WIN_OEM_FJ_JISHO:
			// case KEY_WIN_OEM_FJ_MASSHOU:
			// case KEY_WIN_OEM_FJ_TOUROKU:
			// case KEY_WIN_OEM_FJ_LOYA:
			// case KEY_WIN_OEM_FJ_ROYA:
			case KEY_CIRCUMFLEX: Circumflex;
			case KEY_EXCLAMATION: Exclaim;
			case KEY_DOUBLE_QUOTE: DoubleQuote;
			case KEY_HASH: Hash;
			case KEY_DOLLAR: Dollar;
			case KEY_PERCENT: Percent;
			case KEY_AMPERSAND: Ampersand;
			case KEY_UNDERSCORE: Underscore;
			case KEY_OPEN_PAREN: LeftParen;
			case KEY_CLOSE_PAREN: RightParen;
			case KEY_ASTERISK: Asterisk;
			case KEY_PLUS: Plus;
			case KEY_PIPE: Pipe;
			case KEY_HYPHEN_MINUS: Minus;
			case KEY_OPEN_CURLY_BRACKET: LeftCurlyBracket;
			case KEY_CLOSE_CURLY_BRACKET: RightCurlyBracket;
			case KEY_TILDE: Tilde;
			// case KEY_VOLUME_MUTE:
			// case KEY_VOLUME_DOWN:
			// case KEY_VOLUME_UP:
			case KEY_COMMA: Comma;
			case KEY_PERIOD: Period;
			case KEY_SLASH: Slash;
			case KEY_BACK_QUOTE: Backquote;
			case KEY_OPEN_BRACKET: LeftBracket;
			case KEY_BACK_SLASH: Backslash;
			case KEY_CLOSE_BRACKET: RightBracket;
			case KEY_QUOTE: Quote;
			case KEY_META: Meta;
			case KEY_ALT_GR: AltGr;
			// case KEY_WIN_ICO_HELP:
			// case KEY_WIN_ICO_00:
			// case KEY_WIN_ICO_CLEAR:
			// case KEY_WIN_OEM_RESET:
			// case KEY_WIN_OEM_JUMP:
			// case KEY_WIN_OEM_PA1:
			// case KEY_WIN_OEM_PA2:
			// case KEY_WIN_OEM_PA3:
			// case KEY_WIN_OEM_WSCTRL:
			// case KEY_WIN_OEM_CUSEL:
			// case KEY_WIN_OEM_ATTN:
			// case KEY_WIN_OEM_FINISH:
			// case KEY_WIN_OEM_COPY:
			// case KEY_WIN_OEM_AUTO:
			// case KEY_WIN_OEM_ENLW:
			// case KEY_WIN_OEM_BACK_TAB:
			// case KEY_ATTN:
			// case KEY_CRSEL:
			// case KEY_EXSEL:
			// case KEY_EREOF:
			// case KEY_PLAY:
			// case KEY_ZOOM:
			// case KEY_PA1:
			// case KEY_WIN_OEM_CLEAR:

			case _: Unknown;
		};
	}

	private var lastTime = 0.0;

	public function update() {
		try {
			var curtime = kinc.System.time();
			var dt = curtime - lastTime;
			lastTime = curtime;
			arcane.Lib.handle_update(dt);
		} catch (e) {
			trace(e.details());
			kinc.System.stop();
		}
	}

	public function shutdown():Void {
		kinc.System.stop();
	}

	public function getAudioDriver():Null<IAudioDriver> {
		return new KincAudioDriver();
	}

	public function getGraphicsDriver():Null<IGraphicsDriver> {
		return new KincDriver(0);
	}

	public function language():String {
		return kinc.System.language().toString();
	}

	public function time():Float {
		return kinc.System.time();
	}

	public function width():Int {
		return kinc.System.width();
	}

	public function height():Int {
		return kinc.System.height();
	}

	public function lockMouse():Void {
		Mouse.lock(0);
	}

	public function unlockMouse():Void {
		Mouse.unlock(0);
	}

	public function canLockMouse():Bool {
		return Mouse.canLock(0);
	}

	public function isMouseLocked():Bool {
		return Mouse.isLocked(0);
	}

	public function showMouse():Void {
		Mouse.show();
	}

	public function hideMouse():Void {
		Mouse.hide();
	}

	public function readFile(path:String, cb:(b:Bytes) -> Void, err:(e:arcane.Assets.AssetError) -> Void):Void {
		thread_pool.addTask(
			() -> readFileInternal(path),
			b -> if (b == null) {
				err(NotFound(path));
			} else {
				cb(b);
			},
			e -> err(Other(path, e.message))
		);
	}

	public function readSavefile(name:String, cb:(Bytes) -> Void, err:(AssetError) -> Void):Void {
		thread_pool.addTask(
			() -> readFileInternal(name, SaveFile),
			b -> if (b == null) {
				err(NotFound(name));
			} else {
				cb(b);
			},
			e -> err(Other(e.message))
		);
	}

	public function writeSavefile(name:String, bytes:Bytes, ?complete:(success:Bool) -> Void):Void {
		thread_pool.addTask(() -> {
			var writer = new kinc.io.FileWriter();
			if (writer.open(name)) {
				writer.write(bytes, bytes.length);
				writer.close();
				true;
			} else {
				false;
			}
		}, complete == null ? _ -> {} : complete);
	}

	public static function readFileInternal(name:String, kind:kinc.io.FileReader.FileType = AssetFile):Null<haxe.io.Bytes> {
		var reader = new kinc.io.FileReader();
		if (reader.open(name, kind)) {
			var size = reader.size();
			var bytes = new hl.Bytes(size);
			if (reader.read(bytes, size) != size) {
				reader.close();
				return null;
			}
			reader.close();
			return bytes.toBytes(size);
		} else {
			return null;
		}
	}
}

@:allow(KincSystem)
private class KincWindow implements IWindow {
	var index:Int = 0;

	@:isVar public var title(get, set):String;
	public var x(get, never):Int;
	public var y(get, never):Int;
	public var width(get, never):Int;
	public var height(get, never):Int;
	public var vsync(get, never):Bool;
	public var mode(get, set):WindowMode;

	public function new(index:Int, title:String) {
		this.index = index;
		@:bypassAccessor this.title = title;
	}

	public function resize(width:Int, height:Int):Void {
		kinc.Window.resize(index, width, height);
	}

	public function move(x:Int, y:Int):Void {
		kinc.Window.move(index, x, y);
	}

	function set_title(value:String):String {
		kinc.Window.setTitle(index, value);
		return value;
	}

	function get_title():String {
		return @:bypassAccessor title;
	}

	function get_x():Int {
		return kinc.Window.x(index);
	}

	function get_y():Int {
		return kinc.Window.y(index);
	}

	public function get_width():Int {
		return kinc.Window.width(index);
	}

	public function get_height():Int {
		return kinc.Window.height(index);
	}

	public function get_vsync():Bool {
		return kinc.Window.vsynced(index);
	}

	public function get_mode():WindowMode {
		return switch kinc.Window.getMode(index) {
			case WINDOWED: Windowed;
			case FULLSCREEN: Fullscreen;
			case EXCLUSIVE_FULLSCREEN: Fullscreen;
		}
	}

	public function set_mode(value:WindowMode):WindowMode {
		kinc.Window.changeMode(index, switch value {
			case Windowed: WINDOWED;
			case Fullscreen: FULLSCREEN;
			case FullscreenExclusive: EXCLUSIVE_FULLSCREEN;
		});
		return value;
	}
}
