package tools;

class Log {
	public static var is_verbose:Bool = false;
	public static var warning_disabled:Bool = false;

    public static function print(msg:String) Sys.print(msg);
    public static function println(msg:String) Sys.println(msg);

	public static function info(msg:String) {
		if (is_verbose)
			Sys.println(msg);
	}

	public static function warning(msg:String) {
		if (!warning_disabled)
			Sys.println("Warning : " + msg);
	}

	public static function error(msg:String, fatal = false) {
		if (fatal) {
			Sys.println("Fatal Error : " + msg);
			Sys.println("Exiting...");
			Sys.exit(1);
		} else {
			Sys.println("Error : " + msg);
		}
	}
}
