package arcane.util;

/*
	import haxe.macro.Expr;
	import haxe.macro.ComplexTypeTools;
	import haxe.macro.TypeTools;

	#if !macro
	@:genericBuild(arcane.util.Tuple.TupleBuilder.build())
	class Tuple<Rest> {}
	#end

	class TupleBuilder {
	#if macro
	public static function build() {
		var t = haxe.macro.Context.getLocalType();
		var type_name:String;
		var type_count:Int;
		var type_params:Array<ComplexType>;
		switch t {
			case TInst(t, _.map(x -> TypeTools.toComplexType(x)) => a):
				type_name = "Tuple" + StringTools.replace([for (t in a) ComplexTypeTools.toString(t)].join(""), ".", "");
				type_count = a.length;
				type_params = a;
			default:
				throw "assert";
		}
		try {
			return haxe.macro.Context.getType(type_name);
		} catch (e) {
			var fields:Array<Field> = [];
			fields.push({
				name: "new",
				doc: "",
				access: [APublic],
				kind: FFun({
					args: [
						for (i in 0...type_count)
							{
								name: "v" + (i + 1),
								type: type_params[i]
							}
					],
					expr: macro $b{
						[
							for (i in 0...type_count) {
								var n = "v" + (i + 1);
								macro this.$n = $i{n};
							}
						]
					}
				}),
				pos: haxe.macro.Context.currentPos()
			});
			for(i in 0...type_count){
				fields.push({
					name: "v" + (i + 1),
					kind: FVar(type_params[i]),
					pos: haxe.macro.Context.currentPos(),
					access: [APublic]
				});
			}
			haxe.macro.Context.defineType({
				pack: [],
				name: type_name,
				pos: haxe.macro.Context.currentPos(),
				kind: TDClass(),
				fields: fields
			});
		}
		return haxe.macro.Context.getType(type_name);
	}
	#end
	}

	#if !macro
	function main() {
	var tup = new Tuple<Int, Float, arcane.Geometry>(0, 5, null);
	trace(tup.v1);
	}
	#end
 */
