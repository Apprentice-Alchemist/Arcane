package arcane.util;

@:forward
abstract Nullable<T>(Null<T>) from T to T {
	@:op(A!) private function ensure_not_null():T {
		if(this == null)
			throw "This shouldn't be null!"
		else
			return @:nullSafety(Off) (this : T);
	}
}
