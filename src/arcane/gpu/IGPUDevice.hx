package arcane.gpu;

import arcane.gpu.IVertexBuffer;
import arcane.gpu.IIndexBuffer;
import arcane.gpu.IBindGroup;
import arcane.gpu.IBindGroupLayout;
import arcane.gpu.ICommandBuffer;
import arcane.gpu.ICommandEncoder;
import arcane.gpu.IComputePass;
import arcane.gpu.IComputePipeline;
import arcane.gpu.IRenderPass;
import arcane.gpu.IRenderPipeline;
import arcane.gpu.ISampler;
import arcane.gpu.IShaderModule;
import arcane.gpu.ITexture;
import arcane.gpu.IUniformBuffer;

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

interface IDisposable {
	/**
	 * Disposes the object, which should not be used anymore after this function has been called.
	 */
	function dispose():Void;
}

interface IDescribed<T> {
	/**
	 * The descriptor associated with this object.
	 * Changing the descriptor's fields after object creation will not have any effect on the object.
	 */
	var desc(default, null):T;
}

interface IGPUDevice extends IDisposable {
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
