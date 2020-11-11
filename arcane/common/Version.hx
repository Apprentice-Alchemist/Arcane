package arcane.common;

@:forward
abstract Version(Ver) from Ver to Ver {
	static final reg = ~/^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/i;
	public inline function new(s:String) {
		if (!reg.match(s))
			throw '$s is not a valid version';
		this = {
			major: Std.parseInt(reg.matched(1)),
			minor: Std.parseInt(reg.matched(2)),
			patch: Std.parseInt(reg.matched(3)),
			other: reg.matched(4),
			build: reg.matched(5)
		};
	}

	@:op(A > B) public static inline function greater(a:Version, b:Version):Bool {
		if (a.major > b.major)
			return true;
		else if (a.major < b.major)
			return false;
		else if (a.minor > b.minor)
			return true;
		else if (a.minor < b.minor)
			return false;
		else if (a.patch > b.patch)
			return true
		else
			return false;
	}

	@:op(A < B) public static inline function smaller(a:Version, b:Version):Bool {
		return b > a;
	}

	@:from inline static function fromString(s:String) {
		return new Version(s);
	}

	@:to public inline function toString():String {
		return '${this.major}.${this.minor}.${this.patch}${this.other == null ? "" : '-${this.other}'}${this.build == null ? "" : '+${this.build}'}';
	}
}

typedef Ver = {
	public var major:Int;
	public var minor:Int;
	public var patch:Int;
	@:optional public var other:String;
	@:optional public var build:String;
}
