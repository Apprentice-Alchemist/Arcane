package arcane.internal.kinc;

import arcane.Assets.AssetError;
import arcane.util.Result;
import hl.BytesAccess;
import haxe.io.Bytes;
import kinc.audio2.Audio;
import arcane.audio.IAudioDevice;
using arcane.Utils;
import arcane.Utils.*;

@:structInit
class AudioBuffer implements IAudioBuffer {
	public var left:Bytes;
	public var right:Bytes;
	public var samples:Int;
	public var sampleRate:Int;
	public var channels:Int;

	public function dispose() {}
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

class KincAudioDriver implements IAudioDevice {
	static final sources:Array<Null<AudioSource>> = [];
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
		for (i in 0...samples) {
			var left = (i % 2) == 0;
			var value:Float = 0.0;
			mutex.acquire();
			for (source in sources) {
				if (source == null)
					continue;
				final buffer = source.buffer;
				final pos = source.position;
				final volume = source.volume;
				value += sampleLinear(left ? buffer.left : buffer.right, pos) * volume;

				value = value > 1.0 ? 1.0 : value < -1.0 ? -1.0 : value;
				if (!left)
					source.position += (buffer.sampleRate / sample_rate);
				if (source.position + 1 >= buffer.samples) {
					if (source.loop)
						source.position = 0;
					else
						sources[sources.indexOf(source)] = null;
				}
			}
			mutex.release();
			abuffer.data.setF32(abuffer.write_location, value);
			abuffer.write_location += 4;
			if (abuffer.write_location >= abuffer.data_size)
				abuffer.write_location = 0;
		}
	}

	public function new() {
		Audio.init();
		Audio.setCallback(mix);
		sample_rate = Audio.getSamplesPerSecond();
		arcane.Lib.update.add((_) -> Audio.update());
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

	static function fromFileKinc(file:String) {
		final sound = kinc.audio1.Sound.create(file);
		final frequency = sound.format.samples_per_second;
		final channels = sound.format.channels;
		final samples = sound.size;
		final left = Bytes.alloc(sound.size * 2);
		final right = Bytes.alloc(sound.size * 2);
		(left : hl.Bytes).blit(0, sound.left, 0, left.length);
		(right : hl.Bytes).blit(0, sound.right, 0, right.length);
		sound.destroy();
		return Ok((({
			left: left,
			right: right,
			samples: samples,
			sampleRate: frequency,
			channels: channels
		} : AudioBuffer) : IAudioBuffer));
	}

	public function fromFile(file:String, cb:Result<IAudioBuffer, AssetError>->Void):Void {
		(cast Lib.system : KincSystem).thread_pool.addTask(() -> {
			trace("loading audio from file", file);
			if (StringTools.endsWith(file, "ogg")) {
				#if arcane_audio_use_fmt
				var bytes = KincSystem.readFileInternal(file).sure();
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
				fromFileKinc(file);
				#end
			} else if (StringTools.endsWith(file, "wav")) {
				var bytes = KincSystem.readFileInternal(file);
				if (bytes == null)
					Err(NotFound(file))
				else {
					final data = new format.wav.Reader(new haxe.io.BytesInput(cast bytes)).read();
					final header = data.header;
					final samples = Std.int(data.data.length / (header.channels * header.bitsPerSample / 8));
					final left = Bytes.alloc(samples * 2);
					final right = Bytes.alloc(samples * 2);
					if (header.channels == 1) {
						for (s in 0...samples) {
							if (header.bitsPerSample == 8) {
								left.setUInt16(s << 1, (data.data.get(s) - 127) >> 8);
								right.setUInt16(s << 1, (data.data.get(s) - 127) >> 8);
							} else if (header.bitsPerSample == 16) {
								left.setUInt16(s * 2, data.data.getUInt16(s * 2));
								right.setUInt16(s * 2, data.data.getUInt16(s * 2));
							}
						}
					} else if (header.channels == 2) {
						for (s in 0...samples) {
							if (header.bitsPerSample == 8) {
								left.setUInt16(s * 2, (data.data.get(s) - 127) >> 8);
								right.setUInt16(s * 2, (data.data.get(s + 1) - 127) >> 8);
							} else if (header.bitsPerSample == 16) {
								left.setUInt16(s * 2, data.data.getUInt16(s * 4));
								right.setUInt16(s * 2, data.data.getUInt16(s * 4));
							}
						}
					}
					Ok((({
						left: left,
						right: right,
						samples: samples,
						sampleRate: header.samplingRate,
						channels: header.channels
					} : AudioBuffer) : IAudioBuffer));
				}
			} else {
				Err(InvalidFormat(file));
			}
		}, (result:Result<IAudioBuffer, AssetError>) -> cb(result), e -> cb(Err(Other(e.message))));
	}

	public function play(buffer:IAudioBuffer, volume:Float, pitch:Float, loop:Bool):IAudioSource {
		var source:AudioSource = {
			buffer: cast buffer,
			volume: volume,
			pitch: pitch,
			loop: loop
		};
		mutex.acquire();
		var found = false;
		for (i => s in sources)
			if (s == null) {
				found = true;
				sources[i] = s;
				break;
			}
		if (!found)
			sources.push(source);
		mutex.release();
		return source;
	}

	public function getVolume(i:IAudioSource) {
		return (cast i : AudioSource).volume;
	}

	public function setVolume(i:IAudioSource, v:Float) {
		mutex.acquire();
		(cast i : AudioSource).volume = v;
		mutex.release();
	}

	public function stop(s:IAudioSource):Void {
		mutex.acquire();
		final s:AudioSource = cast s;
		for (i => source in sources) {
			if (source == s) {
				sources[i] = null;
				break;
			}
		}
		mutex.release();
	}
}
