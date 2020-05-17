package arcane.adv.sound;

import openfl.media.SoundTransform;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.Assets;

class SoundHandler{
    public static var instance:SoundHandler;

    @:isVar public var music_volume(get,set):Float;
	public function get_music_volume():Float
		return music_volume;

	public function set_music_volume(v:Float):Float {
		return music_volume = v;
	}
    @:isVar public var sound_volume(get,set):Float;
	public function get_sound_volume():Float return sound_volume;
	public function set_sound_volume(v:Float):Float {if(music != null){music.soundTransform.volume = v;}; return sound_volume = v;}

    var music:SoundChannel;
    public function new(){
        Engine.stage.addEventListener("enter_frame",enter_frame);
        instance = this;
    }
    public function enter_frame(_){}
    
    public function playSfx(sfx_path:String){
        var s = Assets.getSound(sfx_path).play(0.0,0,new SoundTransform(sound_volume,0));
    }
    public function setBgm(path:String){
        if(music != null) music.stop();
        var s = Assets.getMusic(path);
		music = s.play(0.0, 1073741823,new SoundTransform(music_volume));
    }
    public function destroy(){
        if(music != null) music.stop();
        music = null;
    }
}