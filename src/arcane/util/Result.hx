package arcane.util;

@:using(arcane.util.Result.ResultUtil)
enum Result<O, E> {
	Ok(value:O);
	Err(error:E);
}

class ResultUtil {
	public static function ok<O, E>(r:Result<O, E>):Bool {
		return switch r {
			case Ok(_): true;
			case Err(_): false;
		}
	}

	public static function err<O, E>(r:Result<O, E>):Bool {
		return switch r {
			case Ok(_): false;
			case Err(_): true;
		}
	}

	public static function expect<O, E>(r:Result<O, E>, message = "expected success"):O {
		return switch r {
			case Ok(value): value;
			case Err(_): throw message;
		}
	}

	public static function fail<O, E>(r:Result<O, E>, message = "expected failure"):E {
		return switch r {
			case Ok(_): throw message;
			case Err(error): error;
		}
	}
}
