package arcane.util;

// #if macro
// import haxe.macro.Expr;
// import haxe.macro.Context;
// using haxe.macro.Tools;
// using Lambda;
// #end
// #if !macro
// @:genericBuild(arcane.util.Tuple.Tuple.build())
// class Tuple<Rest> {}
// #else
// class Tuple {
// 	public static function build() {
// 		var t = haxe.macro.Context.getLocalType();
// 		var args = haxe.macro.Context.getCallArguments();
// 		var type_name:String;
// 		var type_count:Int;
// 		var type_params:Array<ComplexType>;
// 		switch t {
// 			case TInst(t, _.map(haxe.macro.TypeTools.toComplexType) => a):
// 				if (a.length == 0 && args != null) {
// 					// try {
// 						type_name = "Tuple" + args.length;
// 						type_count = args.length;
// 						type_params = [for (e in args) Context.typeof(e).toComplexType()];
// 					// } catch (_) {
// 					// 	type_name = "Tuple" + a.length;
// 					// 	type_count = a.length;
// 					// 	type_params = a;
// 					// }
// 				} else {
// 					type_name = "Tuple" + a.length;
// 					type_count = a.length;
// 					type_params = a;
// 				}
// 			default:
// 				throw "assert";
// 		}
//         try {
// 			haxe.macro.Context.getType("arcane.tuple." + type_name);
// 		} catch (e) {
// 			var fields:Array<Field> = [];
// 			fields.push({
// 				name: "new",
// 				doc: "",
// 				access: [APublic, AInline],
// 				kind: FFun({
// 					args: [
// 						for (i in 0...type_count)
// 							{
// 								name: "v" + (i + 1),
// 								type: TPath({pack: [], name: "T" + (i + 1)})
// 							}
// 					],
// 					expr: macro $b{
// 						[
// 							for (i in 0...type_count) {
// 								var n = "v" + (i + 1);
// 								macro this.$n = $i{n};
// 							}
// 						]
// 					}
// 				}),
// 				pos: haxe.macro.Context.currentPos()
//             });
//             fields.push({
//                 name: "toString",
//                 kind: FFun({
// 					args: [],
// 					// there's probably a better way to do this
//                     expr: macro return $e{type_params.mapi((index, item) -> macro $i{"v" + (index + 1)}).foldi((e,r,i) -> macro $r + $e{if(i > 0) macro "," else macro ""} + $e,macro "(")} + ")"
//                 }),
//                 pos: haxe.macro.Context.currentPos()
//             });
// 			for (i in 1...(type_count + 1)) {
// 				fields.push({
// 					name: "v" + i,
// 					kind: FVar(TPath({pack: [], name: "T" + i})),
// 					pos: haxe.macro.Context.currentPos(),
// 					access: [APublic]
// 				});
// 			}
// 			haxe.macro.Context.defineType({
// 				pack: ["arcane", "tuple"],
// 				name: type_name,
// 				pos: haxe.macro.Context.currentPos(),
// 				kind: TDClass(),
// 				fields: fields,
// 				params: [
// 					for (i in 1...type_count + 1)
// 						{name: "T" + i}
// 				],
// 				meta: [
// 					// {
// 					// 	name: ":generic",
// 					// 	pos: haxe.macro.Context.currentPos()
// 					// }
// 				]
// 			});
// 		}
// 		return TPath({pack: ["arcane", "tuple"], name: type_name, params: [for (t in type_params) TPType(t)]});
// 	}
// }
// #end
// #if !macro
// function main() {
// 	var tup = new Tuple<Int, Float, arcane.Geometry>(0, 5, null);
// 	var tup2 = new Tuple(0, 5.0, null);
// 	// var tup2 = new Tuple(0, 5., tup);
//     trace(tup.v1, tup.v2, tup.v3);
//     trace(Std.string(tup2));
// 	// trace(tup2.v1, tup2.v2, tup2.v3);
// }
// #end
