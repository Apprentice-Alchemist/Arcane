package arcane.signal;

#if macro
import haxe.macro.Expr.Field;
import haxe.macro.Context;

using haxe.macro.Tools;
#end

@:autoBuild(arcane.signal.IDispatcher.MacroDispatcher.build())
@:remove
interface IDispatcher {
	var __dispatcher:SignalDispatcher;
	public function dispatch(s:Signal):Void;
	public function listen(name:String, cb:Signal->Void):Void;
	public function hasListener(name:String):Bool;
	public function removeListener(name:String, cb:Signal->Void):Void;
}

#if macro
class MacroDispatcher {
	public static function build():Array<Field> {
		var SD = haxe.macro.Context.getType("arcane.signal.SignalDispatcher").getClass();
		var fields = haxe.macro.Context.getBuildFields();
		var type = haxe.macro.Context.getLocalType().getClass();
		var __dispatcher:haxe.macro.Expr.Field = {
			name: "__dispatcher",
			access: [APublic],
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
