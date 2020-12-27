package arcane.adv;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;

class Macro {
	public macro static function initManifest(ae:ExprOf<Array<String>>) {
		var path = haxe.macro.Context.defined("resourcesPath") ? haxe.macro.Context.definedValue("resourcesPath") : "res";
		var files = [];
		function readRec(f:Array<String>, basePath:String) {
			for (f1 in f) {
				if (sys.FileSystem.isDirectory(haxe.io.Path.normalize(/*path + "/" +*/ basePath + "/" + f1))) {
					readRec(sys.FileSystem.readDirectory(haxe.io.Path.normalize(/*path + "/" +*/ basePath + "/" + f1)),
						haxe.io.Path.normalize(basePath + "/" + f1));
				} else {
					files.push(basePath + "/" + f1);
				}
			}
		}
		readRec(sys.FileSystem.readDirectory(path), path);
		return macro $b{[for (x in files) macro $e{ae}.push($v{x})]};
	}

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
