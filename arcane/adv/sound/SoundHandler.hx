package arcane.adv.sound;

import openfl.media.SoundTransform;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.Assets;

class SoundHandler{
    var music_volume:Float;
    var sound_volume:Float;

    var music:SoundChannel;
    public function new(){
        Engine.stage.addEventListener("enter_frame",enter_frame);
    }
    public function enter_frame(_){

    }
    public function playSfx(sfx_path:String){
        var s = Assets.getSound(sfx_path).play(0.0,0,new SoundTransform(sound_volume,0));
    }
    public function setBgm(path:String){
        if(music != null) music.stop();
        var s = Assets.getMusic(path);
		music = s.play(0.0, 1073741823,new SoundTransform(music_volume));
    }
}