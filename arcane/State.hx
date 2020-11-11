package arcane;

import h2d.Camera;

/**
 * A base state you can extend
 */
class State extends h2d.Layers implements IState {
	override public function new()
		super();
	public function create():Void {}
	public function onResize() {}
	public function update(dt:Float):Void {}
	public function destroy():Void {}
	public function dispose():Void {}
}
