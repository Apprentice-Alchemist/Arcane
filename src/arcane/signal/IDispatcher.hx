package arcane.signal;

/*
#if macro
import haxe.macro.Expr.Field;
import haxe.macro.Context;

using haxe.macro.Tools;
#end

// @:autoBuild(arcane.signal.IDispatcher.MacroDispatcher.build())

@:remove
interface IDispatcher {
	public function dispatch<T:Dynamic>(s:Signal<T>):Void;
	public function listen<T:Dynamic>(name:String, cb:Signal<T>->Void):Void;
	public function hasListener<T:Dynamic>(name:String):Bool;
	public function removeListener<T:Dynamic>(name:String, cb:Signal<T>->Void):Void;
}

#if macro
class MacroDispatcher {
	public static function build():Array<Field> {
		var SD = haxe.macro.Context.getType("arcane.signal.SignalDispatcher").getClass();
		var fields = haxe.macro.Context.getBuildFields();
		var type = haxe.macro.Context.getLocalType().getClass();
		if (type.pack.concat(["SignalDispatcher"]).join(".") == "arcane.signal.SignalDispatcher")
			return fields;
		var __dispatcher:Field = {
			name: "__dispatcher",
			access: [],
			pos: SD.pos,
			kind: FieldType.FVar(haxe.macro.Context.getType("arcane.signal.SignalDispatcher").toComplexType(), macro new arcane.signal.SignalDispatcher())
		}

		var dispatch:Field = {
			name: "dispatch",
			access: [APublic],
			kind: FFun({
				args: [
					{
						type: Context.getType("arcane.signal.Signal").toComplexType(),
						name: "s",
					}
				],
				ret: null,
				expr: macro return __dispatcher.dispatch(s)
			}),
			pos: SD.findField("dispatch").pos
		}

		var listen:Field = {
			name: "listen",
			access: [APublic],
			kind: FFun({
				args: [
					{
						type: Context.getType("String").toComplexType(),
						name: "name",
					},
					{
						type: TFunction([Context.getType("arcane.signal.Signal").toComplexType()], Context.getType("Void").toComplexType()),
						name: "cb"
					}
				],
				ret: null,
				expr: macro return __dispatcher.listen(name, cb)
			}),
			pos: SD.findField("listen").pos
		}
		var hasListener:Field = {
			name: "hasListener",
			access: [APublic],
			kind: FFun({
				args: [
					{
						type: Context.getType("String").toComplexType(),
						name: "name",
					}
				],
				ret: Context.getType("Bool").toComplexType(),
				expr: macro return __dispatcher.hasListener(name)
			}),
			pos: SD.findField("hasListener").pos
		}
		var removeListener:Field = {
			name: "removeListener",
			access: [APublic],
			kind: FFun({
				args: [
					{
						type: Context.getType("String").toComplexType(),
						name: "name",
					},
					{
						type: TFunction([Context.getType("arcane.signal.Signal").toComplexType()], Context.getType("Void").toComplexType()),
						name: "cb"
					}
				],
				ret: null,
				expr: macro return __dispatcher.removeListener(name, cb)
			}),
			pos: SD.findField("removeListener").pos
		}
		fields.push(__dispatcher);
		fields.push(dispatch);
		fields.push(listen);
		fields.push(hasListener);
		fields.push(removeListener);
		return fields;
	}
}
#end
*/
