package arcane.controls;

import lime.app.Application;
import lime.app.IModule;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.Event;
import openfl.events.EventDispatcher;


class Controls extends EventDispatcher{
    public static var instance:Controls;
    public function new(){
        super();
        instance = this;
		Engine.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		Engine.stage.addEventListener(KeyboardEvent.KEY_UP,onKeyUp);
		Engine.stage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
		Engine.stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUp);
		Engine.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onMouseDownR);
		Engine.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onMouseUpR);
        Engine.stage.addEventListener(MouseEvent.MOUSE_WHEEL,onMouseWheel);
    }

    function onKeyDown(e:Event){

    }
    function onKeyUp(e:Event){

    }
    function onMouseDown(e:Event){

    }
    function onMouseUp(e:Event){

    }
    function onMouseDownR(e:Event){

    }
    function onMouseUpR(e:Event){

    }
    function onMouseWheel(e:Event){
        
    }
}