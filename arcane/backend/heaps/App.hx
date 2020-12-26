package arcane.backend.heaps;

#if heaps
@:access(arcane)
class App extends hxd.App {
	override function init() {
		if (HeapsLib.initCb != null)
			HeapsLib.initCb();
	}

	override function update(dt:Float) {
		Lib.update(dt);
	}

	override function onResize() {
		Lib.onResize();
	}
}
#end