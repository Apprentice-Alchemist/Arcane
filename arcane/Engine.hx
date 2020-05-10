package arcane;

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
    static var _sound:SoundHandler;
    public static function get_sound() return _sound == null ? _sound = new SoundHandler() : _sound;
    static function init() {
        Lib.current.stage.removeEventListener("enter_frame",enter_frame);
        Lib.current.stage.addEventListener("enter_frame",enter_frame);
        new Controls();
        _sound = new SoundHandler();
    }
    static var frame_listeners:Array<Dynamic>;
    static function enter_frame(e:Event){

    }

}