package arcane;

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
    
    static function init() {
        Lib.current.stage.removeEventListener("enter_frame",enter_frame);
        Lib.current.stage.addEventListener("enter_frame",enter_frame);
        new Controls();
    }
    static var frame_listeners:Array<Dynamic>;
    static function enter_frame(e:Event){

    }

}