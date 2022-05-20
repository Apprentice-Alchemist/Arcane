package arcane.gpu;

import arcane.gpu.IGPUDevice;

@:structInit class TextureDescriptor {
	public final width:Int;
	public final height:Int;
	public final format:arcane.Image.PixelFormat;
	public final data:Null<haxe.io.Bytes> = null;
	public final isRenderTarget:Bool = false;
}

interface ITexture extends IDisposable extends IDescribed<TextureDescriptor> {
	function upload(bytes:haxe.io.Bytes):Void;
}
