package arcane.internal;

import haxe.macro.Expr;
import haxe.macro.Context;

class Macros {
	public macro static function initManifest(ae:ExprOf<Array<String>>) {
		var path = haxe.macro.Context.defined("resourcesPath") ? haxe.macro.Context.definedValue("resourcesPath") : "res";
		var files = [];
		function readRec(f:Array<String>, basePath:String) {
			for (f1 in f) {
				if(sys.FileSystem.isDirectory(haxe.io.Path.normalize(/*path + "/" +*/ basePath + "/" + f1))) {
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
	// public static macro function initBackends(bm_expr:Expr,pb_expr:Expr){
	//     var cp = Context.getClassPath();
	//     var backends = new Map<String,haxe.macro.Expr>();
	//     return macro null;
	//     // return macro { ${bm_expr} = new Map<String,arcane.internal.Backend>(); ${pb_expr} = "hello";};
	// }
}
