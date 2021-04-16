package arcane.signal;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.Tools;
#end
using StringTools;
using Lambda;

#if !macro
@:generic @:genericBuild(arcane.signal.Event.build())
class Event<Rest> {}
#else
class Event {
	public static function build() {
		switch haxe.macro.Context.getLocalType() {
			case TInst(_.get().name => "Event", params):
				var name = "Event" + params.length;
				try {
					var t = Context.getType("arcane.signal." + name);
					return TPath({
						pack: ["arcane", "signal"],
						name: name,
						params: [for (p in params) TPType(p.toComplexType())]
					});
				} catch (_) {
					var cparams = [
						for (idx => _ in params)
							TPath({
								pack: [],
								name: "T" + idx
							})
					];
					var ftype:ComplexType = TFunction(cparams, macro:Void);
					var base = macro class {
						var listeners:List<$ftype> = new List();

						public function new() {}

						public function add(cb:$ftype) {
							listeners.add(cb);
						}

						public function remove(cb:$ftype) {
							listeners.remove(cb);
						}
					};
					base.pack = ["arcane", "signal"];
					base.name = name;
					base.params = [
						for (i => p in params)
							{
								name: "T" + i
							}
					];
					base.fields.push({
						name: "trigger",
						kind: FFun({
							args: [
								for (idx => p in cparams)
									{
										name: "a" + idx,
										type: p
									}
							],
							ret: macro:Void,
							expr: macro for (l in listeners) l($a{cparams.mapi((i, _) -> macro $i{'a$i'})})
						}),
						pos: base.pos,
						access: [APublic]
					});

					Context.defineType(base);
					return TPath({
						pack: ["arcane", "signal"],
						name: name,
						params: [for (p in params) TPType(p.toComplexType())]
					});
				}
			default:
				throw "expected TInst";
		}
	}
}
#end
