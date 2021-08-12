package arcane.internal.kinc;

import arcane.util.Result;
import hl.BytesAccess;
import haxe.io.Bytes;
import kinc.audio1.Sound;
import kinc.audio2.Audio;
import arcane.system.IAudioDriver;

@:structInit
class AudioBuffer implements IAudioBuffer {
	public var data:Bytes;

	// public var left:Bytes;
	// public var right:Bytes;
	public var samples:Int;
	public var sampleRate:Int;
	public var channels:Int;

	public function dispose() {
		// sound.destroy();
	}
}

@:structInit
class AudioSource implements IAudioSource {
	public var buffer:AudioBuffer;
	public var volume:Float;
	public var pitch:Float;
	public var loop:Bool;
	public var position:Float = 0.0;

	public function dispose() {}
}

#if arcane_audio_use_fmt
typedef OggFile = hl.Abstract<"fmt_ogg">;
#end

class KincAudioDriver implements IAudioDriver {
	static final sources:Array<AudioSource> = [];
	static final mutex = new sys.thread.Mutex();

	static inline function lerp(a:Float, b:Float, w:Float) {
		return a * (1 - w) + b * w;
	}

	inline static function g(i:hl.UI16):Int
		return (i : Int) & 0x8000 != 0 ? (i : Int) - 0x10000 : i;

	inline static function clamp(i:Float, a:Float, b:Float) {
		return (i > a ? a : (i < b ? b : i));
	}

	static inline function sampleLinear(data:hl.BytesAccess<hl.UI16>, position:Float):Float {
		var pos1:Int = Math.floor(position);
		var pos2:Int = Math.floor(position + 1);
		var sample1:Float = g(data[pos1]) / 32767.0;
		var sample2:Float = g(data[pos2]) / 32767.0;
		var a:Float = position - pos1;
		return sample1 * (1 - a) + sample2 * a;
	}

	static var sample_rate = 0;

	static function mix(abuffer:kinc.audio2.Buffer, samples:Int) {
		for (_ in 0...samples) {
			// var left = (i % 2) == 0;
			var value:Float = 0.0;
			mutex.acquire();
			for (source in sources) {
				final buffer = source.buffer;
				value += sampleLinear(buffer.data, source.position);
				// if (!left)
				source.position += (buffer.sampleRate / sample_rate);
				if (source.position + 1 >= buffer.samples) {
					source.position = 0;
				}
			}
			mutex.release();
			abuffer.data.setF32(abuffer.write_location, value);
			abuffer.write_location += 4;
			if (abuffer.write_location >= abuffer.data_size)
				abuffer.write_location = 0;
		}
	}

	var sampling_rate:Int;

	public function new() {
		Audio.init();
		Audio.setCallback(mix);
		sampling_rate = sample_rate = Audio.getSamplesPerSecond();
		mutex.acquire();
		sources.resize(0);
		mutex.release();
	}

	#if arcane_audio_use_fmt
	@:nullSafety(Off)
	@:hlNative("fmt", "ogg_open") static function ogg_open(bytes:hl.Bytes, size:Int):OggFile {
		return null;
	}

	@:hlNative("fmt", "ogg_seek") static function ogg_seek(o:OggFile, sample:Int):Bool {
		return false;
	}

	@:hlNative("fmt", "ogg_info") static function ogg_info(o:OggFile, bitrate:hl.Ref<Int>, freq:hl.Ref<Int>, samples:hl.Ref<Int>, channels:hl.Ref<Int>):Void {}

	@:hlNative("fmt", "ogg_read") static function ogg_read(o:OggFile, output:hl.Bytes, size:Int, format:Int):Int {
		return 0;
	}
	#end

	public function fromFile(s:String, cb:Result<IAudioBuffer, Any>->Void):Void {
		(cast Lib.system : KincSystem).thread_pool.addTask(() -> {
			if (StringTools.endsWith(s, "ogg")) {
				#if arcane_audio_use_fmt
				var bytes = KincSystem.readFileInternal(s).sure();
				var file = ogg_open(bytes, bytes.length);
				var bitrate = 0, frequency = 0, samples = 0, channels = 0;
				ogg_info(file, bitrate, frequency, samples, channels);
				var output = haxe.io.Bytes.alloc(samples * channels * 2);
				var out:hl.Bytes = output;
				var needed = output.length;
				while (needed > 0) {
					var read = ogg_read(file, out, needed, 2);
					assert(read >= 0, "decoding error");
					if (read == 0) {
						output.fill(0, needed, 0);
						break;
					}
					needed -= read;
					out = out.offset(read);
				}
				({
					data: output,
					samples: samples,
					sampleRate: frequency,
					channels: channels
				} : AudioBuffer);
				#else
				var s = kinc.audio1.Sound.create(s);
				var frequency = s.format.samples_per_second;
				var channels = s.format.channels;
				var samples = Std.int(s.size);
				var output = Bytes.alloc(s.size * 4);
				var out:hl.BytesAccess<hl.UI16> = output;
				for (i in 0...s.size) {
					out[i * 2] = s.left[i];
					out[i * 2 + 1] = s.right[i];
				}
				s.destroy();
				({
					data: output,
					samples: samples,
					sampleRate: frequency,
					channels: channels
				} : AudioBuffer);
				#end
			} else if (StringTools.endsWith(s, "wav")) {
				var bytes = KincSystem.readFileInternal(s);
				if(bytes == null) cb(Err("not found"));
				final data = new format.wav.Reader(new haxe.io.BytesInput(cast bytes)).read();
				final header = data.header;
				final samples = Std.int(data.data.length / (header.channels * header.bitsPerSample / 8));
				({
					data: data.data,
					samples: samples,
					sampleRate: header.samplingRate,
					channels: header.channels
				} : AudioBuffer);
			} else
				throw "";
		}, (b:AudioBuffer) -> cb(Ok(b)), e -> throw e);
	}

	public function play(buffer:IAudioBuffer, volume:Float, pitch:Float, loop:Bool):IAudioSource {
		var s:AudioSource = {
			buffer: cast buffer,
			volume: volume,
			pitch: pitch,
			loop: loop
		};
		mutex.acquire();
		sources.push(s);
		mutex.release();
		return s;
	}

	public function getVolume(i:IAudioSource) return 1.0;

	public function setVolume(i, v) {}

	public function stop(s:IAudioSource):Void {
		mutex.acquire();
		sources.remove(cast s);
		mutex.release();
	}
}
