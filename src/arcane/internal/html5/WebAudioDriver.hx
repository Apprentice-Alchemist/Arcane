package arcane.internal.html5;

import arcane.Assets.AssetError;
import arcane.util.Result;
import js.html.audio.GainNode;
import js.html.audio.AudioContext;
import js.html.audio.AudioBufferSourceNode;
import js.html.audio.AudioBuffer as WebAudioBuffer;
import arcane.audio.IAudioDevice;

@:structInit
class AudioBuffer implements IAudioBuffer {
	public var buffer:WebAudioBuffer;

	public var samples:Int;

	public var sampleRate:Int;

	public var channels:Int;

	public function dispose() {}
}

class AudioSource implements IAudioSource {
	public var source:AudioBufferSourceNode;
	public var buffer:WebAudioBuffer;
	public var volume:Float;
	public var loop:Bool;
	public var driver:WebAudioDriver;
	public var gain:GainNode;

	public function new(driver:WebAudioDriver, buffer:AudioBuffer, volume:Float, loop:Bool) {
		this.buffer = buffer.buffer;
		this.volume = volume;
		this.loop = loop;
		this.driver = driver;
		this.source = driver.context.createBufferSource();
		this.gain = driver.context.createGain();
		this.gain.gain.value = volume;
		this.source.buffer = this.buffer;
		this.source.connect(this.gain);
		this.gain.connect(driver.context.destination);
		this.source.start();
		this.source.loop = loop;
	}

	public function dispose() {
		this.source.stop();
		this.source.disconnect(this.gain);
		this.gain.disconnect(this.driver.context.destination);
	}
}

@:nullSafety(Strict)
class WebAudioDriver implements IAudioDevice {
	public var context:AudioContext;

	public function new() {
		context = new AudioContext();
		arcane.Lib.onEvent.add(e -> switch e {
			case KeyDown(_), KeyUp(_), KeyPress(_), MouseDown(_, _, _), MouseUp(_, _, _), MouseEnter, MouseLeave:
				context.resume();
			case _:
		});
	}

	public function fromFile(path:String, cb:Result<IAudioBuffer, AssetError>->Void) {
		Assets.loadBytesAsync(path, bytes -> {
			context.decodeAudioData(bytes.getData()).then(b -> {
				var buffer:AudioBuffer = {
					buffer: b,
					channels: b.numberOfChannels,
					sampleRate: Std.int(b.sampleRate),
					samples: b.length
				};
				cb(Ok(buffer));
			}).catchError(e -> cb(Err(InvalidFormat(path))));
		}, e -> cb(Err(e)));
	}

	public function play(buffer:IAudioBuffer, volume:Float, pitch:Float, loop:Bool):IAudioSource {
		return new AudioSource(this, cast buffer, volume, loop);
	}

	public function getVolume(s:IAudioSource):Float {
		return cast(s, AudioSource).gain.gain.value;
	}

	public function setVolume(s:IAudioSource, v:Float):Void {
		cast(s, AudioSource).gain.gain.value = v;
	}

	public function stop(s:IAudioSource) {
		cast(s, AudioSource).source.stop();
	}
}
