package arcane.controls;

import openfl.events.Event;

interface IClickable {
    public function onClick(e:Event):Void;
    public function onHover(h:Bool):Void;
    public function canSelect():Bool;
    public function getBounds():Dynamic;
}