package arcane.internal.empty;

import arcane.common.arrays.ArrayBuffer;
import arcane.common.arrays.Int32Array;
import arcane.common.arrays.Float32Array;
import arcane.system.IGraphicsDriver;

private class BindGroupLayout implements IBindGroupLayout {
	public function new(desc) {}
}

private class BindGroup implements IBindGroup {
	public function new(desc) {}
}

private class RenderPipeline implements IRenderPipeline {
	public var desc(default, null):RenderPipelineDescriptor;

	public function new(desc) {
		this.desc = desc;
	}

	public function dispose() {}
}

private class ComputePipeline implements IComputePipeline {
	public var desc(default, null):ComputePipelineDescriptor;

	public function new(desc) {
		this.desc = desc;
	}

	public function dispose() {}
}

private class Shader implements IShaderModule {
	public var desc(default, null):ShaderDescriptor;

	public function new(desc) {
		this.desc = desc;
	}

	public function dispose() {}
}

private class VertexBuffer implements IVertexBuffer {
	public var desc(default, null):VertexBufferDescriptor;

	var buf_stride:Int = 0;

	public function new(desc) {
		this.desc = desc;
		for (l in desc.attributes)
			buf_stride += switch l.kind {
				case Float1: 1;
				case Float2: 2;
				case Float3: 3;
				case Float4: 4;
				case Float4x4: 16;
			}
	}

	public function dispose() {}

	public function stride():Int {
		return buf_stride;
	}

	public function upload(start:Int, arr:Float32Array):Void {}

	public function map(start:Int, range:Int):Float32Array {
		return new Float32Array(range == -1 ? desc.size * buf_stride : range);
	}

	public function unmap():Void {}
}

private class IndexBuffer implements IIndexBuffer {
	public var desc(default, null):IndexBufferDescriptor;

	public function new(desc) {
		this.desc = desc;
	}

	public function dispose() {}

	public function upload(start:Int, arr:Int32Array):Void {}

	public function map(start:Int, range:Int):Int32Array {
		return new Int32Array(desc.size);
	}

	public function unmap():Void {}
}

private class UniformBuffer implements IUniformBuffer {
	public var desc(default, null):UniformBufferDescriptor;

	public function new(desc) {
		this.desc = desc;
	}

	public function dispose() {}

	public function upload(start:Int, arr:ArrayBuffer):Void {}

	public function map(start:Int, range:Int):ArrayBuffer {
		return new ArrayBuffer(desc.size);
	}

	public function unmap():Void {}
}

private class Texture implements ITexture {
	public var desc(default, null):TextureDescriptor;

	public function new(desc) {
		this.desc = desc;
	}

	public function dispose() {}

	public function upload(bytes:haxe.io.Bytes):Void {}
}

private class RenderPass implements IRenderPass {
	public function new(desc:RenderPassDescriptor) {}

	public function setPipeline(p:IRenderPipeline) {}

	public function setVertexBuffer(b:IVertexBuffer) {}

	public function setVertexBuffers(buffers:Array<IVertexBuffer>) {}

	public function setIndexBuffer(b:IIndexBuffer) {}

	public function setBindGroup(index:Int, b:IBindGroup) {}

	public function draw(start:Int, count:Int) {}

	public function drawInstanced(instanceCount:Int, start:Int, count:Int) {}

	public function end() {}
}

private class ComputePass implements IComputePass {
	public function new(desc:ComputePassDescriptor) {}

	public function setPipeline(p:IComputePipeline) {}

	public function setBindGroup(index:Int, b:IBindGroup) {}

	public function compute(x:Int, y:Int, z:Int) {}
}

private class CommandEncoder implements ICommandEncoder {
	public function new() {}

	public function beginRenderPass(desc:RenderPassDescriptor) {
		return new RenderPass(desc);
	}

	public function beginComputePass(desc:ComputePassDescriptor) {
		return new ComputePass(desc);
	}

	public function finish() {
		return new CommandBuffer();
	}
}

private class CommandBuffer implements ICommandBuffer {
	public function new() {}
}

class EmptyGraphicsDriver implements IGraphicsDriver {
	public final features:DriverFeatures = {
		compute: false,
		instancedRendering: false,
		flippedRenderTargets: false,
		multipleColorAttachments: false,
		uintIndexBuffers: false
	};

	public final limits:DriverLimits = {};

	public function new() {}

	public function getName(details:Bool = false) {
		return "Empty Driver";
	}

	public function dispose():Void {}

	public function present():Void {}

	public function createVertexBuffer(desc:VertexBufferDescriptor):IVertexBuffer {
		return new VertexBuffer(desc);
	}

	public function createIndexBuffer(desc:IndexBufferDescriptor):IIndexBuffer {
		return new IndexBuffer(desc);
	}

	public function createTexture(desc:TextureDescriptor):ITexture {
		return new Texture(desc);
	}

	public function createShader(desc:ShaderDescriptor):IShaderModule {
		return new Shader(desc);
	}

	public function createRenderPipeline(desc:RenderPipelineDescriptor):IRenderPipeline {
		return new RenderPipeline(desc);
	}

	public function getCurrentTexture():ITexture {
		return new Texture({
			width: 0,
			isRenderTarget: false,
			height: 0,
			format: RGBA,
			data: null
		});
	}

	public function createUniformBuffer(desc:UniformBufferDescriptor):IUniformBuffer {
		return new UniformBuffer(desc);
	}

	public function createComputePipeline(desc:ComputePipelineDescriptor):IComputePipeline {
		return new ComputePipeline(desc);
	}

	public function createBindGroupLayout(desc:BindGroupLayoutDescriptor):IBindGroupLayout {
		return new BindGroupLayout(desc);
	}

	public function createBindGroup(desc:BindGroupDescriptor):IBindGroup {
		return new BindGroup(desc);
	}

	public function createCommandEncoder():ICommandEncoder {
		return new CommandEncoder();
	}

	public function submit(buffers:Array<ICommandBuffer>) {}
}
