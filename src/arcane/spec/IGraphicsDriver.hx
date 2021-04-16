package arcane.spec;

enum ShaderKind {
	Vertex;
	Fragment;
}

enum VertexData {
	Float1;
	Float2;
	Float3;
	Float4;
}

enum Face {
	None;
	Back;
	Front;
	Both;
}

enum Blend {
	One;
	Zero;
	SrcAlpha;
	SrcColor;
	DstAlpha;
	DstColor;
	OneMinusSrcAlpha;
	OneMinusSrcColor;
	OneMinusDstAlpha;
	OneMinusDstColor;
}

enum Compare {
	Always;
	Never;
	Equal;
	NotEqual;
	Greater;
	GreaterEqual;
	Less;
	LessEqual;
}

enum StencilOp {
	Keep;
	Zero;
	Replace;
	Increment;
	IncrementWrap;
	Decrement;
	DecrementWrap;
	Invert;
}

enum MipMap {
	None;
	Nearest;
	Linear;
}

enum Filter {
	Nearest;
	Linear;
}

enum Wrap {
	Clamp;
	Repeat;
	// Mirrored;
}

enum Operation {
	Add;
	Sub;
	ReverseSub;
	Min;
	Max;
}

typedef InputLayout = Array<{var name:String; var kind:VertexData;}>;

@:structInit class BlendDesc {
	public var src:Blend = One;
	public var dst:Blend = Zero;
	public var alphaSrc:Blend = One;
	public var alphaDst:Blend = Zero;
	public var op:Operation = Add;
	public var alphaOp:Operation = Add;
}

@:structInit class StencilDesc {
	public var readMask:Int = 0xff;
	public var writeMask:Int = 0xff;
	public var reference:Int = 0;

	public var frontTest:Compare = Always;
	public var frontPass:StencilOp = Keep;
	public var frontSTfail:StencilOp = Keep;
	public var frontDPfail:StencilOp = Keep;

	public var backTest:Compare = Always;
	public var backPass:StencilOp = Keep;
	public var backSTfail:StencilOp = Keep;
	public var backDPfail:StencilOp = Keep;
}

@:structInit class PipelineDesc {
	public var blend:BlendDesc = {};
	public var stencil:StencilDesc = {};
	public var culling:Face = None;
	public var depthWrite:Bool = false;
	public var depthTest:Compare = Always;
	public var inputLayout:InputLayout;
	public var vertexShader:IShader;
	public var fragmentShader:IShader;
}

@:structInit class VertexBufferDesc {
	public var layout:InputLayout;
	public var size:Int;
	public var dyn:Bool = true;
}

@:structInit class IndexBufferDesc {
	public var size:Int;
	public var is32:Bool = true;
}

@:structInit class TextureDesc {
	public var width:Int;
	public var height:Int;
	public var format:arcane.Image.PixelFormat;
	public var data:Null<haxe.io.Bytes> = null;
	public var isRenderTarget:Bool = false;
}

@:structInit class ShaderDesc {
	/**
	 * The platform specific shader data
	 */
	public var data:haxe.io.Bytes;

	/**
	 * What kind of shader it is, right now only Vertex and Fragment shaders are supported
	 */
	public var kind:ShaderKind;

	// @:optional public var fromGlslSrc:Bool = false;
}

interface IDisposable {
	/**
	 * Dispose native resources. The object should not be used after this function has been called.
	 */
	public function dispose():Void;
}

interface IDescribed<T> {
	/**
	 * The descriptor associated with this object.
	 * Editing the descriptor's fields after object creation will not have any effect on the object.
	 */
	public var desc(default, null):T;
}

interface ITextureUnit {}
interface IConstantLocation {}

interface IPipeline extends IDisposable extends IDescribed<PipelineDesc> {
	public function getConstantLocation(name:String):IConstantLocation;
	public function getTextureUnit(name:String):ITextureUnit;
}

interface IShader extends IDisposable extends IDescribed<ShaderDesc> {}

interface IVertexBuffer extends IDisposable extends IDescribed<VertexBufferDesc> {
	/**
	 * Upload vertex data to the gpu
	 * @param start
	 * @param arr
	 */
	public function upload(start:Int = 0, arr:Array<Float>):Void;
}

interface IIndexBuffer extends IDisposable extends IDescribed<IndexBufferDesc> {
	/**
	 * Upload index data to the gpu
	 * @param start
	 * @param arr
	 */
	public function upload(start:Int = 0, arr:Array<Int>):Void;
}

interface ITexture extends IDisposable extends IDescribed<TextureDesc> {
	public function upload(bytes:haxe.io.Bytes):Void;
}

enum GraphicsDriverFeature {
	UIntIndexBuffer;
	InstancedRendering;
}

interface IGraphicsDriver {
	public final renderTargetFlipY:Bool;

	public function supportsFeature(f:GraphicsDriverFeature):Bool;
	public function dispose():Void;

	public function begin():Void;
	public function clear(?col:arcane.common.Color, ?depth:Float, ?stencil:Int):Void;
	public function end():Void;
	public function flush():Void;
	public function present():Void;

	public function createVertexBuffer(desc:VertexBufferDesc):IVertexBuffer;
	public function createIndexBuffer(desc:IndexBufferDesc):IIndexBuffer;
	public function createTexture(desc:TextureDesc):ITexture;
	public function createShader(desc:ShaderDesc):IShader;
	public function createPipeline(desc:PipelineDesc):IPipeline;

	public function setRenderTarget(?t:ITexture):Void;
	public function setPipeline(p:IPipeline):Void;
	public function setVertexBuffer(b:IVertexBuffer):Void;
	public function setIndexBuffer(b:IIndexBuffer):Void;
	public function setTextureUnit(t:ITextureUnit, tex:ITexture):Void;
	public function setConstantLocation(l:IConstantLocation, f:Array<Float>):Void;
	public function draw(start:Int = 0, count:Int = -1):Void;
	public function drawInstanced(instanceCount:Int, start:Int = 0, count:Int = -1):Void;
}
