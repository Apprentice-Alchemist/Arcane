package arcane.internal;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;

using haxe.macro.Tools;
#end

class Macros {
	public macro static function initManifest() {
		var path = haxe.macro.Context.defined("resourcesPath") ? haxe.macro.Context.definedValue("resourcesPath") : "res";
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
}
