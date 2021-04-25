package arcane.signal;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

#if !macro
@:genericBuild(arcane.signal.Event.build())
class Event<Rest> {}
#else
class Event {
	public static function build() {
		switch Context.getLocalType() {
			case TInst(_.get().name => "Event", params):
				var name = "Event" + params.length;
				try {
					var t = Context.getType("arcane.signal." + name);
					return TPath({
						pack: ["arcane", "signal"],
						name: name,
						params: [for (t in params) TPType(Context.toComplexType(t))]
					});
				} catch (_) {
					var cparams = [
						for (i in 0...params.length)
							TPath({
								pack: [],
								name: "T" + i
							})
					];
					var ftype:ComplexType = TFunction(cparams, macro:Void);
					var base = macro class $name {
						var listeners:List<$ftype> = new List();

						public function new() {}
						/**
						 * Adds a listener. Does not overwrite previous instances of itself.
						 */
						public function add(cb:$ftype) {
							listeners.add(cb);
						}
                        
						/**
						 * Removes a listener. Only removes the first found instance of itself.
						 */
						public function remove(cb:$ftype) {
							listeners.remove(cb);
						}
					};
					base.pack = ["arcane", "signal"];
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
								for (i => p in cparams)
									{
										name: "a" + i,
										type: p
									}
							],
							ret: macro :Void,
                            expr: macro for (l in listeners) l($a{Lambda.mapi(cparams,(i, _) -> macro $i{'a$i'})}),
						}),
						pos: base.pos,
                        access: [APublic],
                        doc: "Trigger all added listeners"
					});

					Context.defineType(base);
					return TPath({
						pack: ["arcane", "signal"],
						name: name,
						params: [for (t in params) TPType(Context.toComplexType(t))]
					});
				}
			default:
				throw "expected TInst";
		}
	}
}
#end
