package arcane.internal.hl;

import arcane.gpu.ITexture;
import arcane.gpu.IVertexBuffer.VertexBufferDescriptor;
import arcane.gpu.IVertexBuffer;
import arcane.gpu.IIndexBuffer.IndexBufferDescriptor;
import arcane.gpu.IIndexBuffer;
import arcane.gpu.IUniformBuffer.UniformBufferDescriptor;
import arcane.gpu.IUniformBuffer;
import arcane.gpu.ITexture.TextureDescriptor;
import arcane.gpu.ISampler.SamplerDescriptor;
import arcane.gpu.ISampler;
import arcane.gpu.IShaderModule.ShaderDescriptor;
import arcane.gpu.IShaderModule;
import arcane.gpu.IRenderPipeline.RenderPipelineDescriptor;
import arcane.gpu.IRenderPipeline;
import arcane.gpu.IComputePipeline.ComputePipelineDescriptor;
import arcane.gpu.IComputePipeline;
import arcane.gpu.IBindGroupLayout.BindGroupLayoutDescriptor;
import arcane.gpu.IBindGroupLayout;
import arcane.gpu.IBindGroup.BindGroupDescriptor;
import arcane.gpu.IBindGroup;
import arcane.gpu.ICommandEncoder;
import arcane.gpu.ICommandBuffer;
import arcane.gpu.IGPUDevice;

private typedef NativeDevice = hl.Abstract<"arcane_gpu_device">;
private typedef NativeBuffer = hl.Abstract<"arcane_gpu_buffer">;

@:hlNative("arcane", "gpu_")
private extern class Native {
	static function createDevice():NativeDevice;
	static function getFeatures(device:NativeDevice):DriverFeatures;
	static function getLimits(device:NativeDevice):DriverLimits;
}

class GPUDevice implements IGPUDevice {
	public final features:DriverFeatures = {
		compute: true,
		instancedRendering: true,
		flippedRenderTargets: true,
		multipleColorAttachments: true,
		uintIndexBuffers: true
	};

	public final limits:DriverLimits = {};

	public function new() {}

	public function getName(details:Bool = true):String {
		throw new haxe.exceptions.NotImplementedException();
	}

	public function getCurrentTexture():ITexture {
		throw new haxe.exceptions.NotImplementedException();
	}

	public function createVertexBuffer(desc:VertexBufferDescriptor):IVertexBuffer {
		throw new haxe.exceptions.NotImplementedException();
	}

	public function createIndexBuffer(desc:IndexBufferDescriptor):IIndexBuffer {
		throw new haxe.exceptions.NotImplementedException();
	}

	public function createUniformBuffer(desc:UniformBufferDescriptor):IUniformBuffer {
		throw new haxe.exceptions.NotImplementedException();
	}

	public function createTexture(desc:TextureDescriptor):ITexture {
		throw new haxe.exceptions.NotImplementedException();
	}

	public function createSampler(desc:SamplerDescriptor):ISampler {
		throw new haxe.exceptions.NotImplementedException();
	}

	public function createShader(desc:ShaderDescriptor):IShaderModule {
		throw new haxe.exceptions.NotImplementedException();
	}

	public function createRenderPipeline(desc:RenderPipelineDescriptor):IRenderPipeline {
		throw new haxe.exceptions.NotImplementedException();
	}

	public function createComputePipeline(desc:ComputePipelineDescriptor):IComputePipeline {
		throw new haxe.exceptions.NotImplementedException();
	}

	public function createBindGroupLayout(desc:BindGroupLayoutDescriptor):IBindGroupLayout {
		throw new haxe.exceptions.NotImplementedException();
	}

	public function createBindGroup(desc:BindGroupDescriptor):IBindGroup {
		throw new haxe.exceptions.NotImplementedException();
	}

	public function createCommandEncoder():ICommandEncoder {
		throw new haxe.exceptions.NotImplementedException();
	}

	public function submit(buffers:Array<ICommandBuffer>) {}

	public function present() {}

	public function dispose() {}
}
