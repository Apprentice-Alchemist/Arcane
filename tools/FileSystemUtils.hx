package tools;

import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;

class FileSystemUtils {
	/**
	 * Recursively copies the contents of the directory `i` to the directory `o`
	 * @param i 
	 * @param o 
	 */
	public static function copyDirectory(srcPath:String, dstPath:String) {
        final srcPath = Path.addTrailingSlash(srcPath);
        final dstPath = Path.addTrailingSlash(dstPath);
		for (file in FileSystem.readDirectory(srcPath)) {
			final src = srcPath + file;
			final dst = dstPath + file;
			if (FileSystem.isDirectory(src)) {
				copyDirectory(src, dst);
			} else {
				File.copy(src, dst);
			}
		}
	}
}
