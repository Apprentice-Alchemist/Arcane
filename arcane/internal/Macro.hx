package arcane.internal;

import haxe.macro.Expr.ExprOf;

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
}
