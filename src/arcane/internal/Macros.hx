package arcane.internal;

import haxe.io.Path;
#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;

using haxe.macro.Tools;
#end

class Macros {
	#if macro
	public static function initBackends() {
		// Sys.println("[arcane] :: finding backends");
		if (!Context.defined("arcane-has-backend")) {
			var path = haxe.io.Path.normalize(Context.resolvePath("arcane/Lib.hx"));
			var arr = path.split("/");
			arr.pop(); // Lib.hx
			arr.pop(); // arcane
			arr.pop(); // src
			path = arr.join("/");
			if (Context.defined("js")) {
				Compiler.addClassPath(Path.join([path, "backends/html5"]));
				// Sys.println("[arcane] :: backend found in 'backends/html5'");
			} else if (Context.defined("hl") && Context.defined("kinc")) {
				Compiler.addClassPath(Path.join([path, "backends/kinc"]));
				// Sys.println("[arcane] :: backend found in 'backends/kinc'");
			} else if (Context.defined("android")) {
				Compiler.addClassPath(Path.join([path, "backends/android"]));
			} else {
				Context.fatalError("[arcane] :: no backend found", Context.currentPos());
			}
		}
	}
	#end

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
