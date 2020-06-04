package arcane.adv.sound;

import hxd.snd.Channel;
import hxd.snd.ChannelGroup;
import hxd.res.Sound;
/**
 * Direct copy of Yanrishatums Music class, with a few changes
 */
class Music {
    public function new(){}
    public var volume(default,set):Float;
    public function set_volume(f:Float) {
        volume = f;
        if(channel != null) channel.volume = 1;
        return f;
    }
	public var current(default, null):Sound;
	public var channelGroup:ChannelGroup;
	var channel:Channel;
	public var FADE_TIME:Float = 0.4;

	public function play(res:Sound, fade:Bool = true) {
		if (res == null) {
			stop(fade);
			return;
		}
		if (channel != null) {
			if (fade) {
				var old = channel;
				old.fadeTo(0, FADE_TIME, () -> old.stop());
			} else {
				channel.stop();
			}
		}
		current = res;
		channel = current.play(true, fade ? 0 : 1, channelGroup);
		if (fade)
			channel.fadeTo(1, FADE_TIME);
	}

	public function transit(res:Sound, jingle:Sound, fadeCurrent:Bool = true, fadeNew:Bool = false) {
		if (res == null) {
			stop(fadeCurrent || fadeNew);
			if (jingle != null) {
				var chn = jingle.play(false, fadeCurrent ? 0 : 1, channelGroup);
				if (fadeCurrent)
					chn.fadeTo(1, FADE_TIME);
			}
			return;
		} else if (jingle == null) {
			play(res, fadeNew);
			return;
		}
		if (channel != null) {
			if (fadeCurrent) {
				var old = channel;
				old.fadeTo(0, FADE_TIME, () -> old.stop());
			} else {
				channel.stop();
			}
		}
		current = res;
		channel = jingle.play(false, fadeCurrent ? 0 : 1, channelGroup);
		var chn = channel;
		if (fadeCurrent)
			channel.fadeTo(1, FADE_TIME);
		channel.onEnd = () -> {
			if (current == res && channel == chn) {
				channel = res.play(true, fadeNew ? 0 : 1, channelGroup);
				if (fadeNew)
					channel.fadeTo(1, FADE_TIME);
			}
		}
	}

	public function jingle(jingle:Sound, fade:Bool = true) {
		if (jingle == null)
			return;
		var oldSong = current;
		var old = channel;
		if (old != null) {
			if (fade) {
				old.fadeTo(0, FADE_TIME, () -> old.pause = true);
			} else {
				old.pause = true;
			}
		}
		channel = jingle.play(false, fade ? 0 : 1, channelGroup);
		var chn = channel;
		if (fade)
			channel.fadeTo(1, FADE_TIME);
		channel.onEnd = function() {
			if (current == oldSong && channel == chn) {
				old.pause = false;
				if (fade)
					old.fadeTo(1, FADE_TIME);
				channel = old;
			}
		}
	}

	public function stop(fade:Bool = true) {
		if (channel != null) {
			if (fade) {
				var chn = channel;
				chn.fadeTo(0, FADE_TIME, () -> chn.stop());
			} else {
				channel.stop();
			}
			channel = null;
			current = null;
		}
	}
}