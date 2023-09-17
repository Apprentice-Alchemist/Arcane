package arcane;

import haxe.io.Bytes;

enum AssetError {
	NotFound(path:String);
	Other(path:String, ?msg:String);

	/**
	 * Ex. when using AudioDriver.fromFile with an unsupported format.
	 */
	InvalidFormat(path:String);
}

@:nullSafety(StrictThreaded)
class Assets {
	static var bytes_cache:Map<String, Bytes> = new Map();

	/**
	 * All the files present in the resource folder at the moment of compilation
	 */
	static var manifest:Array<String> = arcane.internal.Macros.initManifest();

	/**
	 * Preload all assets for further use with Assets.getBytes.
	 * @param onProgress called every time an individual asset is loaded
	 * @param handle_error called when an error occurs (ex an asset from the manifest can't be found)
	 * @param onComplete called once all assets have been loaded
	 */
	public static function preload(onProgress:(f:Float) -> Void, handle_error:(error:AssetError) -> Void, onComplete:() -> Void):Void {
		var loaded_files:Int = 0;
		var errored_files:Int = 0;
		final file_count:Int = manifest.length;
		for (x in manifest) {
			loadBytesAsync(x, bytes -> {
				loaded_files++;
				onProgress(loaded_files / file_count);
				if ((file_count + errored_files) == loaded_files) {
					onComplete();
				}
			}, error -> {
				errored_files++;
				handle_error(error);
			});
		}
	}

	/**
	 * Get bytes from the cache.
	 */
	public static function getBytes(path:String):Null<Bytes> {
		return bytes_cache.get(path);
	}

	/**
	 * Loads bytes from `path` asynchronously.
	 * @param cache Wether to cache the bytes in `bytes_cache` for further use with getBytes.
	 */
	public static function loadBytesAsync(path:String, cb:(bytes:Bytes) -> Void, err:(error:AssetError) -> Void, cache:Bool = true) {
		Lib.system.readFile(path, data -> {
			if (cache)
				bytes_cache.set(path, data);
			cb(data);
		}, err);
	}
}
