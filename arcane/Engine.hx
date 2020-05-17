package arcane;

import haxe.Constraints.Function;
import arcane.adv.sound.SoundHandler;
import openfl.events.Event;
import openfl.display.Stage;
import openfl.Lib;
import arcane.adv.*;
import arcane.controls.Controls;

class Engine{
    public static var container(get,never):Container;
    static function get_container() return App.instance.container;

    public static var controls(get,never):Controls;
    public static function get_controls() return Controls.instance;
    
    public static var stage(get,never):Stage;
    static function get_stage() return (Lib.current != null) ? (Lib.current.stage != null ? Lib.current.stage : null) : null;
    
	public static var sound(get, never):SoundHandler;
    public static function get_sound() return SoundHandler.instance;

    static function init() {
        Lib.current.stage.removeEventListener("enter_frame",enter_frame);
        Lib.current.stage.addEventListener("enter_frame",enter_frame);
        new Controls();
        new SoundHandler();
    }
    static var frame_listeners:Array<Function>;
    static var nframe_listeners:Array<Function>;
    static function enter_frame(e:Event){}
    public static function addEnterFrame(f:Function,time:Bool = true){
        switch time {
            case true : if(!(frame_listeners.indexOf(f) > -1)) frame_listeners.push(f);
            case false : if(!(nframe_listeners.indexOf(f) > -1)) nframe_listeners.push(f);
        }
    }


}