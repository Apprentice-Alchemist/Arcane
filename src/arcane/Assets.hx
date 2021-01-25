package arcane;

#if target.threaded
import arcane.util.ThreadPool;
#end
import haxe.io.Bytes;

@:nullSafety(StrictThreaded)
class Assets {
	static var bytes_cache:Map<String, Bytes> = new Map();

	/**
	 * All the files present in the resource folder at the moment of compilation
	 */
	static var manifest:Array<String> = [];

	#if target.threaded
	/**
	 * The thread pool used for asynchronous task loading.
	 * Loaded lazily.
	 */
	public static var thread_pool(get, never):ThreadPool;

	@:noCompletion private static var _thread_pool:Null<ThreadPool>;

	private static function get_thread_pool():ThreadPool {
		if (_thread_pool == null) {
			_thread_pool = new ThreadPool();
		}
		return cast _thread_pool;
	}
	#end

	public static function loadManifest():Array<String> {
		#if (sys && !arcane_use_manifest)
		var manifest = [];
		var pathes:Array<String> = (cast(haxe.macro.Compiler.getDefine("resourcesPath") != null ? haxe.macro.Compiler.getDefine("resourcesPath") : "res"))
			.split(",");
		function readRec(f:Array<String>, basePath:String) {
			for (f1 in f) {
				var p = haxe.io.Path.normalize(basePath + "/" + f1);
				if (p.indexOf(".git") > -1)
					continue;
				if (sys.FileSystem.isDirectory(p)) {
					readRec(sys.FileSystem.readDirectory(p), p);
				} else {
					manifest.push(p);
				}
			}
		}
		for (path in pathes) {
			readRec(sys.FileSystem.readDirectory(path), path);
		}
		return manifest;
		#else
		return arcane.internal.Macros.initManifest();
		#end
	}

	public static function preload(onProgress:Float->Void, handle_error:(file:String, err:Dynamic) -> Void, onComplete:Void->Void):Void {
		#if target.threaded
		thread_pool.addTask(null, task -> {
			task.out_data = loadManifest();
		}, task -> {
			Assets.manifest = cast(task.out_data);
		#else
		Assets.manifest = loadManifest();
		#end
			var loaded_files:Int = 0;
			var errored_files:Int = 0;
			var file_count:Int = manifest.length;
			for (x in manifest) {
				loadBytesAsync(x, function(bytes) {
					bytes_cache.set(x, bytes);
					loaded_files++;
					onProgress(loaded_files / file_count);
					if ((file_count + errored_files) == loaded_files) {
							onComplete();
					}
				}, function(error) {
					errored_files++;
					handle_error(x, error);
				});
			}
		#if target.threaded
		}, task -> {});
		#end
	}

	/**
	 * Get bytes from the cache.
	 * @param path
	 * @return Null<Bytes>
	 */
	public static function getBytes(path:String):Null<Bytes> {
		return bytes_cache.get(path);
	}

	/**
	 * Load bytes from a file.
	 * @param path Path to the file from which the bytes should be loaded.
	 * @param cache Wether to cache the bytes for use with `getBytes`.
	 */
	public static function loadBytes(path:String, cache:Bool = true) {
		#if js
		throw "Synchronous loading not supported on javascript!";
		#elseif sys
		var b = sys.io.File.getBytes(path);
		if (cache)
			bytes_cache.set(path, b);
		return b;
		#end
	}

	public static function loadBytesAsync(path:String, cb:Bytes->Void, err:Dynamic->Void, preloading = false) {
		#if js
		var xhr = new js.html.XMLHttpRequest();
		xhr.open('GET', path, true);
		xhr.responseType = js.html.XMLHttpRequestResponseType.ARRAYBUFFER;
		// xhr.onerror = function(e) err(xhr.statusText);
		xhr.onload = function(e) {
			if (xhr.status != 200) {
				err(xhr.statusText);
				return;
			}
			cb(haxe.io.Bytes.ofData(xhr.response));
		}
		xhr.send();
		#elseif target.threaded
		thread_pool.addTask(path, function(t) {
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
}
