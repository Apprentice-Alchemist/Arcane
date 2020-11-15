package arcane.internal;

@:access(arcane)
class App extends hxd.App {
	override function init() {
		Lib.onInit();
	}

	override function update(dt:Float) {
		Lib.update(dt);
	}

	override function onResize() {
		Lib.onResize();
	}
}
