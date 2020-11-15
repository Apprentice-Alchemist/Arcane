package arcane.d2d;

import hxd.res.DefaultFont;
import hxd.fs.FileEntry;
#if target.threaded
import arcane.util.ThreadPool;
#end

class Preloader extends h2d.Object {
	var file_count:Int = 0;
	var files_loaded:Int;
	var files:Array<String> = [];
	var text:h2d.Text;
	var thread_pool:ThreadPool;

	override public function new(parent) {
		super(parent);
		text = new h2d.Text(DefaultFont.get(), this);
		function readRecursive(x:FileEntry) {
			if (x.isDirectory) for (f in x)
				readRecursive(f);
			else {
				files.push(x.path);
				file_count++;
			}
		}
		readRecursive(hxd.Res.loader.fs.getRoot());
		thread_pool = new ThreadPool();
	}

	public function start() {
		for (x in files) {
			thread_pool.addTask({
				in_data: x,
				out_data: null,
				execute: t -> {
					t.out_data = hxd.Res.loader.loadCache(t.in_data, hxd.res.Resource);
				},
				complete: t -> {
					files_loaded++;
				}
			});
		}
	}

	public function update(dt:Float) {
		// trace("update");
		thread_pool.process();
		if (files_loaded == file_count) {
			thread_pool.dispose();
			thread_pool = null;
			onEnd();
		};
		text.text = Std.string('$files_loaded / $file_count');
	}

	public dynamic function onEnd() {}
}
