package arcane.util;

@:using(arcane.util.Result.ResultUtil)
enum Result<O, E> {
	Ok(s:O);
	Err(f:E);
}

class ResultUtil {
	public static function expect<O, E>(r:Result<O, E>, message = "expected success"):O {
		return switch r {
			case Ok(s): s;
			case Err(_): throw message;
		}
	}

	public static function fail<O, E>(r:Result<O, E>, message = "expected failure"):E {
		return switch r {
			case Ok(_): throw message;
			case Err(f): f;
		}
	}
}
