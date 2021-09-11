package arcane.util;

@:using(arcane.util.Result.ResultUtil)
enum Result<O, E> {
	Ok(value:O);
	Err(error:E);
}

private class ResultUtil {
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
