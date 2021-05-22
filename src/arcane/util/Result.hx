package arcane.util;

@:using(arcane.util.Result.ResultUtil)
enum Result<S, F> {
	Success(s:S);
	Failure(f:F);
}

class ResultUtil {
	public static function expect<S, F>(r:Result<S, F>, message = "expected success"):S {
		switch r {
			case Success(s):
				return s;
			case Failure(_):
				throw message;
		}
	}

	public static function fail<S, F>(r:Result<S, F>, message = "expected failure"):F {
		switch r {
			case Success(_):
				throw message;
			case Failure(f):
				return f;
		}
	}
}
