package arcane.internal;

import haxe.io.Path;
#if macro
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Expr;

using haxe.macro.Tools;
#end

class Macros {
	public macro static function initManifest() {
		var path = Context.defined("resourcesPath") ? Context.definedValue("resourcesPath") : "res";
		var files = [];
		function readRec(f:Array<String>, basePath:String) {
			for (f1 in f) {
				var p = haxe.io.Path.normalize(basePath + "/" + f1);
				if (sys.FileSystem.isDirectory(p)) {
					readRec(sys.FileSystem.readDirectory(p), p);
				} else {
					files.push(p);
				}
			}
		}
		readRec(sys.FileSystem.readDirectory(path), path);
		return macro $v{files};
	}

	#if macro
	public static function findArcane():String {
		var file = switch Context.getType("arcane.Utils") {
			case TInst(t, _): t.get().pos.getInfos().file;
			case _: throw "wtf";
		}
		var p = Path.normalize(Path.join([Path.directory(file), "..", ".."]));
		return p;
	}
	#end
}
