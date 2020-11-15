package arcane.audio;

import hxd.snd.ChannelGroup;
import hxd.res.Sound;
import hxd.snd.Channel;

@:allow(arcane)
class Audio {
	public static var FADE_TIME = 1.0;

	@:isVar public var musicVolume(get, set):Float;

	function get_musicVolume():Float
		return musicGroup.volume;

	function set_musicVolume(f:Float):Float {
		musicVolume = f;
		return musicGroup.volume = f;
	}

	public var musicGroup(default, default):ChannelGroup;

	public var sfxGroup(default, default):ChannelGroup;
	public var currentMusic(default, null):Null<Channel>;
	public var currentSfx(default, null):Null<Channel>;

	private function new() {
		musicGroup = new ChannelGroup("arcane_music");
		sfxGroup = new ChannelGroup("arcane_sfx");
	}

	public function playMusic(s:Sound, looping:Bool = true, fade:Bool = true) {
		if (currentMusic != null) {
			if (fade) {
				currentMusic.fadeTo(0, FADE_TIME, function() {
					currentMusic.stop();
					currentMusic = s.play(looping, 0, musicGroup);
					currentMusic.fadeTo(1, FADE_TIME);
				});
			}
			else {
				currentMusic.stop();
				currentMusic = s.play(looping, 1, musicGroup);
			}
		}
		else {
			if (fade) {
				currentMusic = s.play(looping, 0, musicGroup);
				currentMusic.fadeTo(1, FADE_TIME);
			}
			else {
				currentMusic = s.play(looping, 1, musicGroup);
			}
		}
	}

	public function stopMusic(fade:Bool = false) {
		if (currentMusic != null) {
			if (fade) {
				currentMusic.fadeTo(0, FADE_TIME, () -> currentMusic.stop());
			}
			else {
				currentMusic.stop();
			}
		}
	}

	public function stopSfx() {
		if (currentSfx != null) {
			currentSfx.stop();
		}
	}

	public function playSfx(s:Sound, loop:Bool = false) {
		if (currentSfx != null) {
			currentSfx.stop();
		}
		currentSfx = s.play(loop, sfxGroup);
	}

	public function mute(bool:Bool) {
		musicGroup.mute = sfxGroup.mute = bool;
	}

	public function dispose() {
		stopMusic(false);
	}
}
