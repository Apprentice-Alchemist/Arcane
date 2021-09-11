package arcane;

@:nullSafety(Strict)
class Image {
	/**
	 * The format of the image.
	 */
	public var format(default, null):PixelFormat;

	/**
	 * Width in pixels of the image.
	 */
	public var width(default, null):Int;

	/**
	 * Height in pixels of the image.
	 */
	public var height(default, null):Int;

	/**
	 * The raw bytes of the image, in the format specified by `this.format`
	 */
	public var data(default, null):haxe.io.Bytes;

	/**
	 * Create a new image with parameters.
	 * If the `bytes` argument is null, this function will allocate some with `haxe.io.Bytes.alloc`.
	 * @param width Width in pixels.
	 * @param height Height in pixels.
	 * @param format Image format.
	 * @param bytes Optional bytes to initalize the image with.
	 */
	public function new(width:Int, height:Int, format:PixelFormat, ?bytes:haxe.io.Bytes):Void {
		this.width = width;
		this.height = height;
		this.format = format;
		if (bytes == null) {
			data = haxe.io.Bytes.alloc(width * height * bytesPerPixel(format));
		} else {
			this.data = bytes;
		}
	}

	/**
	 * Returns a copy of the current image.
	 * @return Image
	 */
	public function clone():Image {
		return new Image(this.width, this.height, this.format, this.data.sub(0, this.data.length));
	}

	/**
	 * Tries to convert the image's pixel data to a specific format.
	 * Returns true if the conversion was successful and false if it wasn't.
	 * Currently supported conversions :
	 * - BGRA to RGBA or ARGB
	 * - RGBA to BGRA or ARGB
	 * - ARGB to BGRA or RGBA
	 */
	public function convert(to:PixelFormat):Bool {
		if (format == to)
			return true;
		switch [format, to] {
			case [BGRA, RGBA] | [RGBA, BGRA]:
				var p = 0;
				inline function bget(i) return data.get(i);
				inline function bset(i, v) data.set(i, v);
				for (_ in 0...data.length >> 2) {
					var b = bget(p);
					var g = bget(p + 1);
					var r = bget(p + 2);
					var a = bget(p + 3);
					bset(p++, r);
					bset(p++, g);
					bset(p++, b);
					bset(p++, a);
				}

			case [BGRA, ARGB] | [ARGB, BGRA]:
				var p = 0;
				inline function bget(i) return data.get(i);
				inline function bset(i, v) data.set(i, v);
				for (_ in 0...data.length >> 2) {
					var b = bget(p);
					var g = bget(p + 1);
					var r = bget(p + 2);
					var a = bget(p + 3);
					bset(p++, a);
					bset(p++, r);
					bset(p++, g);
					bset(p++, b);
				}
			case [ARGB, RGBA]:
				var p = 0;
				inline function bget(i) return data.get(i);
				inline function bset(i, v) data.set(i, v);
				for (_ in 0...data.length >> 2) {
					var a = bget(p);
					var r = bget(p + 1);
					var g = bget(p + 2);
					var b = bget(p + 3);
					bset(p++, r);
					bset(p++, g);
					bset(p++, b);
					bset(p++, a);
				}
			case [RGBA, ARGB]:
				var p = 0;
				inline function bget(i) return data.get(i);
				inline function bset(i, v) data.set(i, v);
				for (_ in 0...data.length >> 2) {
					var r = bget(p);
					var g = bget(p + 1);
					var b = bget(p + 2);
					var a = bget(p + 3);
					bset(p++, a);
					bset(p++, r);
					bset(p++, g);
					bset(p++, b);
				}
			default:
				return false;
		}
		format = to;
		return true;
	}

	/**
	 * Create an image from png encoded bytes.
	 * Requires the `format` haxelib.
	 * @param b raw png bytes
	 */
	public static function fromPngBytes(b:haxe.io.Bytes):Image {
		#if format
		var reader = new format.png.Reader(new haxe.io.BytesInput(b));
		var data = reader.read();
		var header = format.png.Tools.getHeader(data);
		var bytes = format.png.Tools.extract32(data);
		var image = new Image(header.width, header.height, BGRA, bytes);
		image.convert(RGBA);
		return image;
		#else
		throw "please install the format haxelib";
		#end
	}

	/**
	 * Returns the amount of bytes each pixel takes up for the given format
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
