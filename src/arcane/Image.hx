package arcane;

import haxe.io.Bytes;
import haxe.io.BytesInput;
#if format
import format.png.Reader as PngReader;
import format.png.Tools as PngTools;
#end

class Image {
	public var format(default, null):PixelFormat;
	public var width(default, null):Int;
	public var height(default, null):Int;
	public var data(default, null):haxe.io.Bytes;

	public function new(width:Int, height:Int, format:PixelFormat, ?bytes:haxe.io.Bytes):Void {
		this.width = width;
		this.height = height;
		this.format = format;
		if(bytes == null){
			data = haxe.io.Bytes.alloc(width * height * bytesPerPixel(format));
		}else{
			this.data = bytes;
		}
	}

	/**
	 * Tries to convert the image's pixel data to a specific format.
	 * Returns true if the conversion was successful and false if it wasn't.
	 * Currently supported conversions :
	 * ```
	 * BGRA -> RGBA | ARGB
	 * RGBA -> BGRA | ARGB
	 * ARGB -> BGRA | RGBA
	 * ```
	 */
	public function convert(to:PixelFormat):Bool {
		if(format == to)
			return true;
		switch [format, to] {
			case [BGRA, RGBA] | [RGBA, BGRA]:
				var p = 0;
				inline function bget(i) return data.get(i);
				inline function bset(i, v) data.set(i, v);
				for (i in 0...data.length >> 2) {
					var b = bget(p);
					var g = bget(p + 1);
					var r = bget(p + 2);
					var a = bget(p + 3);
					bset(p++, r);
					bset(p++, g);
					bset(p++, b);
					bset(p++, a);
				}
				// return true;
			case [BGRA, ARGB] | [ARGB, BGRA]:
				var p = 0;
				inline function bget(i) return data.get(i);
				inline function bset(i, v) data.set(i, v);
				for (i in 0...data.length >> 2) {
					var b = bget(p);
					var g = bget(p + 1);
					var r = bget(p + 2);
					var a = bget(p + 3);
					bset(p++, a);
					bset(p++, r);
					bset(p++, g);
					bset(p++, b);
				}
				// return true;

			case [ARGB, RGBA]:
				var p = 0;
				inline function bget(i) return data.get(i);
				inline function bset(i, v) data.set(i, v);
				for (i in 0...data.length >> 2) {
					var a = bget(p);
					var r = bget(p + 1);
					var g = bget(p + 2);
					var b = bget(p + 3);
					bset(p++, r);
					bset(p++, g);
					bset(p++, b);
					bset(p++, a);
				}
				// return true;
			case [RGBA, ARGB]:
				var p = 0;
				inline function bget(i) return data.get(i);
				inline function bset(i, v) data.set(i, v);
				for (i in 0...data.length >> 2) {
					var r = bget(p);
					var g = bget(p + 1);
					var b = bget(p + 2);
					var a = bget(p + 3);
					bset(p++, a);
					bset(p++, r);
					bset(p++, g);
					bset(p++, b);
				}
				// return true;
			default:
				return false;
		}
		format = to;
		return true;
	}

	/**
	 * Requires the `format` haxelib.
	 * @param b raw png bytes
	 */
	public static function fromPngBytes(b:haxe.io.Bytes):Null<Image> {
		#if format
		var reader = new PngReader(new BytesInput(b));
		var data = reader.read();
		var header = PngTools.getHeader(data);
		var bytes = PngTools.extract32(data);
		return new Image(header.width, header.height, BGRA, bytes);
		#else
		return null;
		#end
	}

	/**
	 * Returns the amount of bytes each pixel takes up for a given format
	 */
	public static function bytesPerPixel(format:PixelFormat):Int {
		return switch format {
			case RGBA | BGRA | ARGB: 4;
			default: 4;
		}
	}
}

enum PixelFormat {
	RGBA;
	BGRA;
	ARGB;
}
