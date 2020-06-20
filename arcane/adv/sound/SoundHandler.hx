package arcane.adv.sound;

import hxd.res.Sound;

@:allow(arcane.Engine)
class SoundHandler {
	public var sfx_vol(default, set):Float;

	function set_sfx_vol(f:Float)
		return f;

	public var mus_vol(default, set):Float;

	function set_mus_vol(f:Float) {
		if (music != null)
			music.volume = f;
		return f;
	}

	public var music(default, null):Music;

	public function new() {
		this.music = new Music();
	}

	public function playSfx(s:Sound) {
		s.play(false, sfx_vol);
	}
}
