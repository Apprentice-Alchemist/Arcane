package arcane.system;

import asl.Ast.ShaderModule;
import arcane.arrays.ArrayBuffer;
import arcane.util.Color;
import arcane.arrays.Float32Array;
import arcane.arrays.Int32Array;

typedef DriverFeatures = {
	/**
	 * Compute is supported on every platform, except webgl.
	 */
	final compute:Bool;

	final uintIndexBuffers:Bool;
	final multipleColorAttachments:Bool;
	final flippedRenderTargets:Bool;
	final instancedRendering:Bool;
};

typedef DriverLimits = {};

enum abstract ShaderStage(Int) {
	var Vertex = 0x1;
	var Fragment = 0x2;
	var Compute = 0x4;

	@:op(A | B) static function and(a:ShaderStage, b:ShaderStage):ShaderStage;
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

enum FilterMode {
	Nearest;
	Linear;
}

enum AddressMode {
	Clamp;
	Repeat;
	Mirrored;
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

@:structInit class BlendDescriptor {
	public final src:Blend = One;
	public final dst:Blend = Zero;
	public final alphaSrc:Blend = One;
	public final alphaDst:Blend = Zero;
	public final op:Operation = Add;
	public final alphaOp:Operation = Add;
}

@:structInit class StencilDescriptor {
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

@:structInit class RenderPipelineDescriptor {
	public final vertexShader:IShaderModule;
	public final fragmentShader:IShaderModule;
	public final inputLayout:InputLayout;
	public final layout:Array<IBindGroupLayout> = [];
	public final blend:BlendDescriptor = {};
	public final stencil:StencilDescriptor = {};
	public final culling:Face = None;
	public final depthWrite:Bool = false;
	public final depthTest:Compare = Always;
}

@:structInit class VertexBufferDescriptor {
	public final attributes:Array<VertexAttribute>;
	public final instanceDataStepRate:Int = 0;
	public final size:Int;
	public final dyn:Bool = true;
}

@:structInit class IndexBufferDescriptor {
	public final size:Int;
	public final is32:Bool = true;
}

@:structInit class UniformBufferDescriptor {
	public final size:Int;
}

@:structInit class SamplerDescriptor {
	public final uAddressing:AddressMode = Clamp;
	public final vAddressing:AddressMode = Clamp;
	public final wAddressing:AddressMode = Clamp;

	public final magFilter:FilterMode = Nearest;
	public final minFilter:FilterMode = Nearest;
	public final mipFilter:FilterMode = Nearest;

	public final lodMinClamp:Float = 0;
	public final lodMaxClamp:Float = 32;

	public final compare:Null<Compare> = null;
	public final maxAnisotropy:Int = 1;
}

@:structInit class TextureDescriptor {
	public final width:Int;
	public final height:Int;
	public final format:arcane.Image.PixelFormat;
	public final data:Null<haxe.io.Bytes> = null;
	public final isRenderTarget:Bool = false;
}

@:structInit class ShaderDescriptor {
	public final module:ShaderModule;
}

private enum BindingResource {
	Buffer(buffer:IUniformBuffer);
	Texture(texture:ITexture);
	Sampler(sampler:ISampler);
}

private enum SamplerBindingType {
	Filtering;
	NonFiltering;
	Comparison;
}

private enum BindingKind {
	Buffer(hasDynamicOffset:Bool, minBindingSize:Int);
	Sampler(type:SamplerBindingType);
	Texture();
}

@:structInit class BindGroupLayoutDescriptor {
	public final entries:Array<{
		var visibility:ShaderStage;
		var binding:Int;
		var kind:BindingKind;
	}>;
}

@:structInit class BindGroupDescriptor {
	public final layout:IBindGroupLayout;
	public final entries:Array<{
		var binding:Int;
		var resource:BindingResource;
	}>;
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
	public final texture:ITexture;

	public final load:LoadOp;
	public final store:StoreOp;

	@:optional public final loadValue:Null<Color>;
}

@:structInit class RenderPassDescriptor {
	public final colorAttachments:Array<ColorAttachment>;
	// public final stencilAttachment:StencilAttachment;
	// public final depthAttachment:DepthAttachment;
}

@:structInit class ComputePassDescriptor {}

@:structInit class ComputePipelineDescriptor {
	public final shader:IShaderModule;
}

private interface IDisposable {
	/**
	 * Disposes the object, which should not be used anymore after this function has been called.
	 */
	function dispose():Void;
}

private interface IDescribed<T> {
	/**
	 * The descriptor associated with this object.
	 * Changing the descriptor's fields after object creation will not have any effect on the object.
	 */
	var desc(default, null):T;
}

interface IRenderPipeline extends IDisposable extends IDescribed<RenderPipelineDescriptor> {}
interface IShaderModule extends IDisposable extends IDescribed<ShaderDescriptor> {}

interface IVertexBuffer extends IDisposable extends IDescribed<VertexBufferDescriptor> {
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

interface IIndexBuffer extends IDisposable extends IDescribed<IndexBufferDescriptor> {
	/**
	 * Upload index data to the gpu
	 * @param start
	 * @param arr
	 */
	function upload(start:Int, arr:Int32Array):Void;

	function map(start:Int, range:Int):Int32Array;
	function unmap():Void;
}

interface IUniformBuffer extends IDisposable extends IDescribed<UniformBufferDescriptor> {
	/**
	 * Upload uniform data to the gpu
	 * @param start
	 * @param arr
	 */
	function upload(start:Int, arr:ArrayBuffer):Void;

	function map(start:Int, range:Int):ArrayBuffer;
	function unmap():Void;
}

interface ITexture extends IDisposable extends IDescribed<TextureDescriptor> {
	function upload(bytes:haxe.io.Bytes):Void;
}

interface IRenderPass {
	function setPipeline(p:IRenderPipeline):Void;
	function setVertexBuffer(b:IVertexBuffer):Void;
	function setVertexBuffers(buffers:Array<IVertexBuffer>):Void;
	function setIndexBuffer(b:IIndexBuffer):Void;
	function setBindGroup(index:Int, group:IBindGroup):Void;

	function draw(start:Int, count:Int):Void;
	function drawInstanced(instanceCount:Int, start:Int, count:Int):Void;

	function end():Void;
}

interface IComputePipeline extends IDisposable extends IDescribed<ComputePipelineDescriptor> {}

interface IComputePass {
	function setBindGroup(index:Int, group:IBindGroup):Void;
	function setPipeline(p:IComputePipeline):Void;
	function dispatch(x:Int, y:Int, z:Int):Void;

	function end():Void;
}

interface ICommandEncoder {
	function beginComputePass(desc:ComputePassDescriptor):IComputePass;
	function beginRenderPass(desc:RenderPassDescriptor):IRenderPass;
	function finish():ICommandBuffer;
}

interface ICommandBuffer {}
interface IBindGroupLayout {}
interface IBindGroup {}
interface ISampler {}

interface IGraphicsDriver extends IDisposable {
	final features:DriverFeatures;
	final limits:DriverLimits;

	function getName(details:Bool = false):String;

	/**
	 * @return The current swapchain image
	 */
	function getCurrentTexture():ITexture;

	function createVertexBuffer(desc:VertexBufferDescriptor):IVertexBuffer;
	function createIndexBuffer(desc:IndexBufferDescriptor):IIndexBuffer;
	function createUniformBuffer(desc:UniformBufferDescriptor):IUniformBuffer;
	function createTexture(desc:TextureDescriptor):ITexture;
	function createSampler(desc:SamplerDescriptor):ISampler;
	function createShader(desc:ShaderDescriptor):IShaderModule;
	function createRenderPipeline(desc:RenderPipelineDescriptor):IRenderPipeline;
	function createComputePipeline(desc:ComputePipelineDescriptor):IComputePipeline;
	function createBindGroupLayout(desc:BindGroupLayoutDescriptor):IBindGroupLayout;
	function createBindGroup(desc:BindGroupDescriptor):IBindGroup;
	function createCommandEncoder():ICommandEncoder;
	function submit(buffers:Array<ICommandBuffer>):Void;
	function present():Void;
}
