package arcane.adv;

import openfl.display.Sprite;
import openfl.net.SharedObject;

class App extends Sprite {
	public static var instance:App;
	public static var saves:SharedObject;
    public static var settings:SharedObject;
	public var container:Container;
	public var top:Sprite;
	override public function new() {
		super();
		instance = this;
		container = new Container();
		addChild(container);
		top = new Sprite();
		addChild(top);
		@:privateAccess Engine.init();
	}
}