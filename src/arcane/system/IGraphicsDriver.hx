package arcane.system;

import arcane.common.Color;
import arcane.common.arrays.Float32Array;
import arcane.common.arrays.Int32Array;

enum ShaderKind {
	Vertex;
	Fragment;
	Compute;
}

enum VertexData {
	Float1;
	Float2;
	Float3;
	Float4;
	Float4x4;
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

typedef VertexAttribute = {
	final name:String;
	final kind:VertexData;
}

typedef InputLayout = Array<{
	final instanced:Bool;
	final attributes:Array<VertexAttribute>;
}>;

@:structInit class BlendDesc {
	public final src:Blend = One;
	public final dst:Blend = Zero;
	public final alphaSrc:Blend = One;
	public final alphaDst:Blend = Zero;
	public final op:Operation = Add;
	public final alphaOp:Operation = Add;
}

@:structInit class StencilDesc {
	public final readMask:Int = 0xff;
	public final writeMask:Int = 0xff;
	public final reference:Int = 0;

	public final frontTest:Compare = Always;
	public final frontPass:StencilOp = Keep;
	public final frontSTfail:StencilOp = Keep;
	public final frontDPfail:StencilOp = Keep;

	public final backTest:Compare = Always;
	public final backPass:StencilOp = Keep;
	public final backSTfail:StencilOp = Keep;
	public final backDPfail:StencilOp = Keep;
}

@:structInit class PipelineDesc {
	public final blend:BlendDesc = {};
	public final stencil:StencilDesc = {};
	public final culling:Face = None;
	public final depthWrite:Bool = false;
	public final depthTest:Compare = Always;
	public final inputLayout:InputLayout;
	public final vertexShader:IShader;
	public final fragmentShader:IShader;
}

@:structInit class VertexBufferDesc {
	public final attributes:Array<VertexAttribute>;
	public final instanceDataStepRate:Int = 0;
	public final size:Int;
	public final dyn:Bool = true;
}

@:structInit class IndexBufferDesc {
	public final size:Int;
	public final is32:Bool = true;
}

@:structInit class TextureDesc {
	public final width:Int;
	public final height:Int;
	public final format:arcane.Image.PixelFormat;
	public final data:Null<haxe.io.Bytes> = null;
	public final isRenderTarget:Bool = false;
}

@:structInit class ShaderDesc {
	public final id:String;

	/**
	 * The kind of shader.
	 */
	public final kind:ShaderKind;

	// @:optional public final fromGlslSrc:Bool = false;
}

enum LoadOp {
	Clear;
	Load;
}

enum StoreOp {
	Store;
	Discard;
}

@:structInit class ColorAttachment {
	@:optional public final texture:Null<ITexture>;

	public final load:LoadOp;
	public final store:StoreOp;

	@:optional public final loadValue:Null<Color>;
}

@:structInit class RenderPassDesc {
	public final colorAttachments:Array<ColorAttachment>;
	// public final stencilAttachment:StencilAttachment;
	// public final depthAttachment:DepthAttachment;
}

private interface IDisposable {
	/**
	 * Dispose native resources. The object should not be used after this function has been called.
	 */
	function dispose():Void;
}

private interface IDescribed<T> {
	/**
	 * The descriptor associated with this object.
	 * Editing the descriptor's fields after object creation will not have any effect on the object.
	 */
	var desc(default, null):T;
}

interface ITextureUnit {}
interface IConstantLocation {}

interface IPipeline extends IDisposable extends IDescribed<PipelineDesc> {
	/**
	 * Get a constant location. (Uniform in opengl.)
	 * If there is no constant location with the given name, return an invalid constant location.
	 * @param name 
	 * @return IConstantLocation
	 */
	function getConstantLocation(name:String):IConstantLocation;

	/**
	 * Get a texture unit. (Sampler in opengl.)
	 * If there is no texture unit with the given name, return an invalid texture unit.
	 * @param name 
	 * @return ITextureUnit
	 */
	function getTextureUnit(name:String):ITextureUnit;
}

interface IShader extends IDisposable extends IDescribed<ShaderDesc> {}

interface IVertexBuffer extends IDisposable extends IDescribed<VertexBufferDesc> {
	/**
	 * Upload vertex data to the gpu
	 * @param start
	 * @param arr
	 */
	function upload(start:Int, arr:Float32Array):Void;

	function map(start:Int, range:Int):Float32Array;
	function unmap():Void;

	function stride():Int;
}

interface IIndexBuffer extends IDisposable extends IDescribed<IndexBufferDesc> {
	/**
	 * Upload index data to the gpu
	 * @param start
	 * @param arr
	 */
	function upload(start:Int, arr:Int32Array):Void;

	function map(start:Int, range:Int):Int32Array;
	function unmap():Void;
}

interface ITexture extends IDisposable extends IDescribed<TextureDesc> {
	function upload(bytes:haxe.io.Bytes):Void;
}

interface IRenderPass {
	function setPipeline(p:IPipeline):Void;
	function setVertexBuffer(b:IVertexBuffer):Void;
	function setVertexBuffers(buffers:Array<IVertexBuffer>):Void;
	function setIndexBuffer(b:IIndexBuffer):Void;
	function setTextureUnit(t:ITextureUnit, tex:ITexture):Void;
	function setConstantLocation(l:IConstantLocation, f:Float32Array):Void;

	function draw(start:Int, count:Int):Void;
	function drawInstanced(instanceCount:Int, start:Int, count:Int):Void;

	function end():Void;
}

interface IGraphicsDriver extends IDisposable {
	final renderTargetFlipY:Bool;
	final instancedRendering:Bool;
	final uintIndexBuffers:Bool;

	function getName(details:Bool = false):String;

	function begin():Void;
	// function clear(?col:arcane.common.Color, ?depth:Float, ?stencil:Int):Void;
	function end():Void;
	function flush():Void;
	function present():Void;

	function createVertexBuffer(desc:VertexBufferDesc):IVertexBuffer;
	function createIndexBuffer(desc:IndexBufferDesc):IIndexBuffer;
	function createTexture(desc:TextureDesc):ITexture;
	function createShader(desc:ShaderDesc):IShader;
	function createPipeline(desc:PipelineDesc):IPipeline;

	function beginRenderPass(desc:RenderPassDesc):IRenderPass;
}
