package arcane;

#if heaps
import hxd.res.Any;
#end
import haxe.io.Bytes;

@:nullSafety(StrictThreaded)
class Assets {
	#if heaps
	public static var asset_cache:Map<String, Any> = new Map();
	#end
	public static var bytes_cache:Map<String, Bytes> = new Map();

	/**
	 * All the files present in the resource folder at the moment of compilation
	 */
	public static var manifest:Array<String> = [];

	// public static function __init__() {
	// 	#if ((js || arcane_use_manifest) && !arcane_no_manifest)
	// 	arcane.internal.Macros.initManifest(manifest);
	// 	#end
	// }

	public static function loadManifest() {
		#if sys
		var path:String = cast haxe.macro.Compiler.getDefine("resourcesPath") != null ? haxe.macro.Compiler.getDefine("resourcesPath") : "res";
		trace(path);
		function readRec(f:Array<String>, basePath:String) {
			for (f1 in f) {
				if (sys.FileSystem.isDirectory(haxe.io.Path.normalize(/*path + "/" +*/ basePath + "/" + f1))) {
					readRec(sys.FileSystem.readDirectory(haxe.io.Path.normalize(/*path + "/" +*/ basePath + "/" + f1)),
						haxe.io.Path.normalize(basePath + "/" + f1));
				} else {
					manifest.push(basePath + "/" + f1);
				}
			}
		}
		readRec(sys.FileSystem.readDirectory(path), path);
		#else
		manifest = [];
		arcane.internal.Macros.initManifest(manifest);
		#end
	}

	public static function preload(onProgress:Float->Void, onComplete:Void->Void) {
		loadManifest();
		var loaded_files:Int = 0;
		var file_count:Int = manifest.length;
		for (x in manifest) {
			loadBytesAsync(x, function(bytes) {
				bytes_cache.set(x, bytes);
				loaded_files++;
				onProgress(loaded_files / file_count);
				if (file_count == loaded_files) {
					onComplete();
				}
			}, function(error) {
				trace(error);
			}, true);
		}
		#if target.threaded
		arcane.util.ThreadPool.awaken();
		#end
	}

	public static function loadBytes(path:String, cache:Bool = true) {
		#if js
		throw "Synchronous loading not supported on javascript!";
		#elseif sys
		var b = sys.io.File.getBytes(path);
		bytes_cache.set(path, b);
		return b;
		#end
	}

	public static function loadBytesAsync(path:String, cb:Bytes->Void, err:Dynamic->Void, preloading = false) {
		#if js
		var xhr = new js.html.XMLHttpRequest();
		xhr.open('GET', path, true);
		xhr.responseType = js.html.XMLHttpRequestResponseType.ARRAYBUFFER;
		xhr.onerror = function(e) err(xhr.statusText);
		xhr.onload = function(e) {
			if (xhr.status != 200) {
				err(xhr.statusText);
				return;
			}
			cb(haxe.io.Bytes.ofData(xhr.response));
		}
		xhr.send();
		#elseif target.threaded
		arcane.util.ThreadPool.addTask(path, function(t) {
			t.out_data = sys.io.File.getBytes(path);
		}, function(t) {
			cb(cast t.out_data);
		}, function(t) {
			err(cast t.error_data);
		}, !preloading);
		#else
		cb(sys.io.File.getBytes(path));
		#end
	}

	#if heaps
	public static function getAsset(path:String):Null<hxd.res.Any> {
		if (asset_cache.exists(path))
			return asset_cache.get(path);
		else if (bytes_cache.exists(path)) {
			asset_cache.set(path, Any.fromBytes(path, cast bytes_cache.get(path)));
			return asset_cache.get(path);
		} else {
			loadBytes(path);
			asset_cache.set(path, Any.fromBytes(path, cast bytes_cache.get(path)));
			return asset_cache.get(path);
		}
	}
	#end
}
