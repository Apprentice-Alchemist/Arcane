package arcane.common;

import haxe.io.Path;

@:forward
abstract Version(V) from V to V {
	public inline function new(s:String) {
		var t = s.split(".");
		var major = Utils.parseInt(t[0]);
		var minor = Utils.parseInt(t[1]);
		var patch = Utils.parseInt(t[2]);
		this = {major: major, minor: minor, patch: patch};
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
		return '${this.major}.${this.minor}.${this.patch}';
	}
}

typedef V = {
	public var major:Int;
	public var minor:Int;
	public var patch:Int;
}
