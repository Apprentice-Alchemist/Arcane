package arcane;

import arcane.util.Result;
#if target.threaded
import arcane.util.ThreadPool;
#end
import haxe.io.Bytes;

enum AssetError {
	NotFound(path:String);
	Other(path:String, ?msg:String);
}

@:nullSafety(Strict)
class Assets {
	static var bytes_cache:Map<String, Bytes> = new Map();

	/**
	 * All the files present in the resource folder at the moment of compilation
	 */
	static var manifest:Array<String> = [];

	#if target.threaded
	/**
	 * The thread pool used for asynchronous task loading.
	 * Initialized lazily.
	 */
	public static var thread_pool(get, never):ThreadPool;

	@:noCompletion static var _thread_pool:Null<ThreadPool>;

	static function get_thread_pool():ThreadPool {
		if (_thread_pool == null) {
			_thread_pool = new ThreadPool(4);
		}
		return _thread_pool;
	}
	#end

	static function loadManifest():Array<String> {
		#if (sys && !arcane_use_manifest)
		final manifest = [];
		final pathes:Array<String> = (cast(haxe.macro.Compiler.getDefine("resourcesPath") != null ? haxe.macro.Compiler.getDefine("resourcesPath") : "res"))
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
			if (sys.FileSystem.exists(path) && sys.FileSystem.isDirectory(path))
				readRec(sys.FileSystem.readDirectory(path), path);
			else
				Log.warn('$path is does not exists or is not a directory.');
		}
		return manifest;
		#else
		return arcane.internal.Macros.initManifest();
		#end
	}

	/**
	 * Preload all assets for further use with Assets.getBytes.
	 * @param onProgress called every time an individual asset is loaded
	 * @param handle_error called when an error occurs (ex an asset from the manifest can't be found)
	 * @param onComplete called once all assets have been loaded
	 * @return Void
	 */
	public static function preload(onProgress:(f:Float) -> Void, handle_error:(error:AssetError) -> Void, onComplete:() -> Void):Void {
		#if target.threaded
		thread_pool.addTask(loadManifest, manifest -> {
			Assets.manifest = manifest;
		#else
		Assets.manifest = loadManifest();
		#end
			var loaded_files:Int = 0;
			var errored_files:Int = 0;
			final file_count:Int = manifest.length;
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
					handle_error(error);
				});
			}
		#if target.threaded
		});
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
	 * Not supported on javascript.
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

	/**
	 * Loads bytes from `path` asynchronously.
	 * @param path
	 * @param cb
	 * @param err
	 * @param cache Wether to cache the bytes in `bytes_cache` for further use with getBytes.
	 */
	public static function loadBytesAsync(path:String, cb:(bytes:Bytes) -> Void, err:(error:AssetError) -> Void, cache:Bool = true) {
		#if js
		var xhr = new js.html.XMLHttpRequest();
		xhr.open('GET', path, true);
		xhr.responseType = js.html.XMLHttpRequestResponseType.ARRAYBUFFER;
		xhr.onload = function(e) {
			if (xhr.status != 200) {
				err(xhr.status == 404 ? NotFound(path) : Other(path, xhr.statusText));
				return;
			}
			final data = haxe.io.Bytes.ofData(xhr.response);
			if (cache)
				bytes_cache.set(path, data);
			cb(data);
		}
		xhr.send();
		#elseif target.threaded
		thread_pool.addTask(() -> {
			if (sys.FileSystem.exists(path)) {
				try
					Success(sys.io.File.getBytes(path))
				catch (e)
					Failure(Other(path, e.message));
			} else {
				Failure(NotFound(path));
			}
		}, result -> {
			switch result {
				case Success(data):
					if (cache)
						bytes_cache.set(path, data);
					cb(data);
				case Failure(e):
					err(e);
			}
		});
		#else
		cb(loadBytes(path, cache));
		#end
	}
}
