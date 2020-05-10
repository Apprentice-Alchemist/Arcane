package arcane.adv;

import openfl.events.Event;
import openfl.display.Sprite;
import openfl.net.SharedObject;

class App extends Sprite {
	public static var instance:App;
	public static var saves:SharedObject;
    public static var settings:SharedObject;
	public var container:Container;
	public var top:Sprite;
	override public function new(?cw:Int = 256,?ch:Int = 144) {
		super();
		instance = this;
		container = new Container(cw,ch);
		addChild(container);
		top = new Sprite();
		addChild(top);
		@:privateAccess Engine.init();
		Engine.stage.addEventListener(Event.RESIZE,onResize);
	}
	public function onResize(e:Event){
		var w = container._width;
		var h = container._height;
	}
}