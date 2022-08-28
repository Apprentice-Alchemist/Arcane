package asl.std;

using StringTools;
using haxe.macro.Tools;
using Lambda;

inline function comp(i:Int) {
	return switch i {
		case 0: "x";
		case 1: "y";
		case 2: "z";
		case 3: "w";
		case _: throw "assert";
	}
}

final comps = ["x", "y", "z", "w"];
final alt_comps = ["r", "g", "b", "a"];

var p2 = {
	var permutations = new Map<String, Bool>();
	for (i in 0...2) {
		for (j in 0...2) {
			permutations.set(comp(i) + comp(j), i != j);
		}
	}
	permutations;
}

var p3 = {
	var permutations = new Map<String, Bool>();
	for (i in 0...3) {
		for (j in 0...3) {
			for (k in 0...3) {
				permutations.set(comp(i) + comp(j) + comp(k), i != j && j != k && i != k);
			}
		}
	}
	permutations;
}

var p4 = {
	var permutations = new Map<String, Bool>();
	for (i in 0...4) {
		for (j in 0...4) {
			for (k in 0...4) {
				for (l in 0...4) {
					permutations.set(comp(i) + comp(j) + comp(k) + comp(l), i != j && i != k && i != l && j != k && j != l && k != l);
				}
			}
		}
	}
	permutations;
}

function buildSwizzles(size:Int) {
	final fields = haxe.macro.Context.getBuildFields();
	function addPermutations(fields:std.Array<haxe.macro.Expr.Field>, permutations:Map<String, Bool>) {
		for (perm => write in permutations) {
			var type = switch perm.length {
				case 2: macro
				:Vec2<T>;
				case 3: macro
				:Vec3<T>;
				case 4: macro
				:Vec4<T>;
				case _: throw "assert";
			}
			fields.push({
				name: perm,
				access: [APublic],
				kind: FProp("get", write ? "set" : "never", type),
				pos: (macro null).pos,
			});
			var vecCtor = switch perm.length {
				case 2: macro asl.std.StdLib.vec2;
				case 3: macro asl.std.StdLib.vec3;
				case 4: macro asl.std.StdLib.vec4;
				case _: throw "assert";
			}
			fields.push({
				name: "get_" + perm,
				kind: FFun({
					args: [],
					expr: macro return (@:swizzle $vecCtor($a{
						(() -> [
							for (i in 0...perm.length) {
								var char = perm.charAt(i);
								macro this.$char;
							}
						])()
					})),
				}),
				pos: (macro null).pos
			});
			if (write) {
				fields.push({
					name: "set_" + perm,
					kind: FFun({
						args: [
							{
								name: "value"
							}
						],
						expr: macro @:swizzle {
							$b{
								[
									for (i in 0...perm.length) {
										var char = perm.charAt(i);
										var c = comp(i);
										macro this.$char = value.$c;
									}
								]
							}
							return value;
						},
					}),
					pos: (macro null).pos
				});
			}
		}
	}

	if (size >= 2) {
		addPermutations(fields, p2);
	}

	if (size >= 3) {
		addPermutations(fields, p3);
	}

	if (size >= 4) {
		addPermutations(fields, p4);
	}
	return fields;
}

// function swizzle(self:haxe.macro.Expr, size:Int, name:String) {
// 	final str = "xrsygtzbpwaq";
// 	var cat = -1;
// 	final out = [];
// 	for (i in 0...name.length) {
// 		var idx = str.indexOf(name.charAt(i));
// 		if (idx < 0)
// 			throw "err";
// 		var icat = idx % 3;
// 		if (cat < 0)
// 			cat = icat
// 		else if (icat != cat)
// 			break; // down't allow .ryz
// 		var cid = Std.int(idx / 3);
// 		if (cid >= size)
// 			throw "err";
// 		// error(typeToString(e.t) + " does not have component " + name.charAt(i), e.pos);
// 		out.push(cid);
// 	}
// 	var comps = out.map(c -> switch c {
// 		case 0: macro __this__.x;
// 		case 1: macro __this__.y;
// 		case 2: macro __this__.z;
// 		case 3: macro __this__.w;
// 		case _: throw "assert";
// 	});
// 	return switch size {
// 		case 2: macro {
// 				var __this__ = $self;
// 				@:swizzle vec2($a{comps});
// 			};
// 		case 3: macro {
// 				var __this__ = $self;
// 				@:swizzle vec3($a{comps});
// 			};
// 		case 4: macro {
// 				var __this__ = $self;
// 				@:swizzle vec4($a{comps});
// 			};
// 		case var l: throw "assert";
// 	}
// }
