package arcane.adv;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;

class Macro {
	

	#if macro
	static function buildSmh() {
		var cls = haxe.macro.Context.getType("arcane.Lib").getClass();
		try {} catch (e:String) {} catch (e:Dynamic) {}
		switch cls.meta.extract("hello")[0].params[0].expr {
			case EConst(CIdent(s)):
			default:
		}
	}
	#end
}
