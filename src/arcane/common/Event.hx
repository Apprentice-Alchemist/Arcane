package arcane.common;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.Tools;
using Lambda;
#end

#if !macro
@:genericBuild(arcane.common.Event.build())
class Event<Rest> {}
#else
class Event {
	public static function build() {
		switch Context.getLocalType() {
			case TInst(_.get().name => "Event", params):
				var cparams:Array<ComplexType> = [];
				var named_params:Array<ComplexType> = [];
				switch params {
					case [TFun(args, _ => TAbstract(_.toString() => "Void", _))]:
						for (a in args) {
							final t = a.t.toComplexType();
							if (a.opt) {
								cparams.push(t);
								named_params.push(TOptional(TNamed(a.name, t)));
							} else {
								cparams.push(t);
								named_params.push(TNamed(a.name, t));
							}
						}
					case _.map(haxe.macro.TypeTools.toComplexType) => p:
						for (t in p) {
							named_params.push(t);
							cparams.push(t);
						}
				}

				var name = "Event" + cparams.length;
				try {
					var t = Context.getType("arcane.common." + name);
					return TPath({
						pack: ["arcane", "common"],
						name: name,
						params: [for (t in cparams) TPType(t)]
					});
				} catch (_) {
					var type_params = [
						for (i in 0...cparams.length)
							TPath({
								pack: [],
								name: "T" + i
							})
					];
					var f_params = named_params.mapi((i, item) -> switch item {
						case TOptional(t): switch t {
								case TNamed(s, _): TOptional(TNamed(s, type_params[i]));
								case _: type_params[i];
							}
						case TNamed(n, _): TNamed(n, type_params[i]);
						case _: type_params[i];
					});
					var ftype:ComplexType = TFunction(f_params, macro:Void);

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
					base.pack = ["arcane", "common"];
					base.params = [
						for (i => p in cparams)
							{
								name: "T" + i
							}
					];
					base.fields.push({
						name: "trigger",
						kind: FFun({
							args: [
								for (i => p in type_params)
									{
										name: "a" + i,
										type: p,
										opt: f_params[i].match(TOptional(_))
									}
							],
							ret: macro:Void,
							expr: macro for (l in listeners) l($a{Lambda.mapi(cparams, (i, _) -> macro $i{'a$i'})}),
						}),
						pos: base.pos,
						access: [APublic],
						doc: "Trigger all added listeners"
					});
					Context.defineType(base);
					return TPath({
						pack: ["arcane", "common"],
						name: name,
						params: [for (t in cparams) TPType(t)]
					});
				}
			default:
				throw "expected TInst";
		}
	}
}
#end
