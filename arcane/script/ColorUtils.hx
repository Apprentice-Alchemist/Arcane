package arcane.script;


// http://stackoverflow.com/a/28938235/2631715

@:enum
abstract Color(Int) {
	var None = 0;
	var Black = 30;
	var Red = 31;
	var Green = 32;
	var Yellow = 33;
	var Blue = 34;
	var Purple = 35;
	var Cyan = 36;
	var White = 37;
}

@:enum
abstract Style(Int) {
	var Normal = 0;
	var Bold = 1;
	var Underline = 4;
}

class ColorUtils {
	public static function println(message:String, color:Color, style:Style = Style.Normal):Void {
		Sys.println(setColor(color, style) + message + setColor(Color.None));
	}

	public static function print(message:String, color:Color, style:Style = Style.Normal):Void {
		Sys.print(setColor(color, style) + message + setColor(Color.None));
	}

	public static function setColor(color:Color, style:Style = Style.Normal):String {
		// if (Sys.systemName() == "Linux" || Sys.systemName() == "Mac") {
			var id = (color == Color.None) ? "" : ';$color';
			return "\033[" + style + id + "m";
		// }
		// return "";
	}
}