package arcane.common;

// TODO : should other and build fields be checked in == and > < <= >=?

@:forward
@:nullSafety(StrictThreaded)
abstract Version(Ver) {
	static final reg:EReg = ~/^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/i;

	public inline function new(s:String) {
		if (!reg.match(s))
			throw '$s is not a valid version';
		this = {
			major: arcane.Utils.parseInt(reg.matched(1)),
			minor: arcane.Utils.parseInt(reg.matched(2)),
			patch: arcane.Utils.parseInt(reg.matched(3)),
			other: reg.matched(4),
			build: reg.matched(5)
		};
	}

	public inline function increasePatch(by:Int = 1):Void {
		this.patch += by;
	}

	public inline function increaseMinor(by:Int = 1):Void {
		this.minor += by;
		this.patch = 0;
	}

	public inline function increaseMajor(by:Int = 1):Void {
		this.major += 1;
		this.minor = this.patch = 0;
	}

	@:op(A == B) public static inline function equals(a:Version, b:Version):Bool
		return a.major == b.major && a.minor == b.minor && a.patch == b.patch && a.other == b.other && a.build == b.build;

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

	@:op(A <= B) public static inline function smallereq(a:Version, b:Version):Bool {
		return equals(a, b) || smaller(a, b);
	}

	@:op(A >= B) public static inline function greatereq(a:Version, b:Version):Bool {
		return equals(a, b) || greater(a, b);
	}

	@:from inline static function fromString(s:String) {
		return new Version(s);
	}

	@:to public inline function toString():String {
		return '${this.major}.${this.minor}.${this.patch}${this.other == null ? "" : '-${this.other}'}${this.build == null ? "" : '+${this.build}'}';
	}
}

@:structInit
class Ver {
	public var major:Int;
	public var minor:Int;
	public var patch:Int;
	public var other:Null<String>;
	public var build:Null<String>;

	public inline function new(major:Int, minor:Int, patch:Int, other:Null<String>, build:Null<String>) {
		this.major = major;
		this.minor = minor;
		this.patch = patch;
		this.other = other;
		this.build = build;
	}
}
