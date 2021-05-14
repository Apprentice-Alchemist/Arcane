package arcane.system;

enum Event {
	KeyDown(k:Int);
	KeyUp(k:Int);
	KeyPress(charcode:Int);

	MouseDown(key:Int, x:Int, y:Int);
	MouseUp(key:Int, x:Int, y:Int);
	MouseEnter;
	MouseLeave;
	MouseMove(dx:Int, dy:Int);
	MouseWheel(delta:Float);
	Resize(w:Int, h:Int);
	FocusGained;
	FocusLost;
}

enum abstract KeyCode(Int) {
    var Unkown;

	var Enter;
	var Escape;
	var Backspace;
	var Tab;
	var Space;
	var Exclaim;
	var DoubleQuote;
	var Hash;
	var Percent;
	var Dollar;
	var Ampersand;
	var Quote;
	var LeftParen;
	var RightParen;
	var Asterisk;
	var Plus;
	var Comma;
	var Minus;
	var Period;
    var Slash;
    
	var LeftBracket;
	var Backslash;
	var RightBracket;
	var Caret;
	var Underscore;
    var Backquote;
    
	var A;
	var B;
	var C;
	var D;
	var E;
	var F;
	var G;
	var H;
	var I;
	var J;
	var K;
	var L;
	var M;
	var N;
	var O;
	var P;
	var Q;
	var R;
	var S;
	var T;
	var U;
	var V;
	var W;
	var X;
	var Y;
    var Z;
    
	var Numpad0;
	var Numpad1;
	var Numpad2;
	var Numpad3;
	var Numpad4;
	var Numpad5;
	var Numpad6;
	var Numpad7;
	var Numpad8;
    var Numpad9;
    
	var Number0;
	var Number1;
	var Number2;
	var Number3;
	var Number4;
	var Number5;
	var Number6;
	var Number7;
	var Number8;
    var Number9;
    
	var F1;
	var F2;
	var F3;
	var F4;
	var F5;
	var F6;
	var F7;
	var F8;
	var F9;
	var F10;
	var F11;
	var F12;
	var F13;
	var F14;
	var F15;
	var F16;
	var F17;
	var F18;
	var F19;
	var F20;
	var F21;
	var F22;
	var F23;
	var F24;
}
