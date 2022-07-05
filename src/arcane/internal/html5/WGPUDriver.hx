package arcane.internal.html5;

import js.lib.ArrayBufferView;
#if js
import js.html.CanvasElement;
#end
#if wgpu_externs
import arcane.arrays.*;
import arcane.gpu.IBindGroupLayout;
import arcane.gpu.IBindGroup;
import arcane.gpu.IRenderPipeline;
import arcane.gpu.IComputePipeline;
import arcane.gpu.IShaderModule;
import arcane.gpu.IVertexBuffer;
import arcane.gpu.IIndexBuffer;
import arcane.gpu.IUniformBuffer;
import arcane.gpu.ITexture;
import arcane.gpu.ISampler;
import arcane.gpu.IRenderPass;
import arcane.gpu.IComputePass;
import arcane.gpu.ICommandEncoder;
import arcane.gpu.ICommandBuffer;
import arcane.gpu.IGPUDevice;
import wgpu.*;

using arcane.Utils;

private typedef BufferChunk = {
	final buffer:GPUBuffer;
	final size:Int;
	var offset:Int;
}

private class StagingBuffers {
	final chunk_size:Int;
	final active_chunks:Array<BufferChunk>;
	final closed_chunks:Array<BufferChunk>;
	final free_chunks:Array<BufferChunk>;

	public function new(size:Int) {
		this.chunk_size = size;
		this.active_chunks = [];
		this.closed_chunks = [];
		this.free_chunks = [];
	}

	public function writeBuffer(device:GPUDevice, encoder:GPUCommandEncoder, target:GPUBuffer, offset:Int, size:Int):ArrayBuffer {
		var chunk:Null<BufferChunk> = null;

		inline function swap_remove<T>(arr:Array<T>, i:Int):T @:nullSafety(Off) {
			final item = arr[i];
			if (arr.length == 1) {
				arr.pop();
			} else {
				arr[i] = arr.pop();
			}
			return item;
		}

		for (i => c in active_chunks) {
			if (c.offset + size <= c.size) {
				trace(c.offset + size, c.size);
				chunk = swap_remove(active_chunks, i);
				break;
			}
		}

		if (chunk == null) {
			for (i => c in free_chunks) {
				if (size <= c.size) {
					chunk = swap_remove(free_chunks, i);
					break;
				}
			}
		}

		final chunk:BufferChunk = if (chunk == null) {
			buffer: device.createBuffer({
				label: "staging",
				size: size > chunk_size ? size : chunk_size,
				usage: MAP_WRITE | COPY_SRC,
				mappedAtCreation: true
			}),
			size: size > chunk_size ? size : chunk_size,
			offset: 0
		} else chunk;
		encoder.copyBufferToBuffer(chunk.buffer, chunk.offset, target, offset, size);
		final old_offset = chunk.offset;
		chunk.offset += size;
		final remainder = chunk.offset % 8;
		if (remainder != 0)
			chunk.offset += (8 - remainder);
		active_chunks.push(chunk);
		return chunk.buffer.getMappedRange(old_offset, size);
	}

	public function finish() {
		while (active_chunks.length > 0) {
			final chunk:BufferChunk = cast active_chunks.pop();
			chunk.buffer.unmap();
			closed_chunks.push(chunk);
		}
	}

	public function recall() {
		while (closed_chunks.length > 0) {
			final chunk:BufferChunk = cast closed_chunks.pop();
			chunk.offset = 0;
			chunk.buffer.mapAsync(WRITE).then(_ -> free_chunks.push(chunk)).catchError(e -> (untyped console).error(e));
		}
	}
}

@:nullSafety(Strict)
private class BindGroupLayout implements IBindGroupLayout {
	public final layout:GPUBindGroupLayout;

	public function new(layout) {
		this.layout = layout;
	}
}

@:nullSafety(Strict)
private class BindGroup implements IBindGroup {
	public final group:GPUBindGroup;

	public function new(group) {
		this.group = group;
	}
}

@:nullSafety(Strict)
private class RenderPipeline implements IRenderPipeline {
	public var desc(default, null):RenderPipelineDescriptor;

	public final pipeline:GPURenderPipeline;

	// public final layout:GPUBindGroupLayout;
	final driver:WGPUDriver;

	public function new(driver:WGPUDriver, desc:RenderPipelineDescriptor) {
		this.desc = desc;
		this.driver = driver;
		var buffers:Array<GPUVertexBufferLayout> = [];
		var i = 0;
		for (l in desc.inputLayout) {
			var stride = 0;
			var attributes:Array<GPUVertexAttribute> = [];
			for (attribute in l.attributes) {
				var offset = stride;
				var format:GPUVertexFormat = switch attribute.kind {
					case Float1:
						stride += 1 * 4;
						FLOAT32;
					case Float2:
						stride += 2 * 4;
						FLOAT32X2;
					case Float3:
						stride += 3 * 4;
						FLOAT32X3;
					case Float4:
						stride += 4 * 4;
						FLOAT32X4;
					case Float4x4:
						stride += 4 * 4 * 4;
						for (_i in 0...4) {
							attributes.push({
								format: FLOAT32X4,
								offset: offset + (_i * 4),
								shaderLocation: i++
							});
						}
						continue;
				}
				attributes.push({
					format: format,
					offset: offset,
					shaderLocation: i++
				});
			}
			buffers.push({
				arrayStride: stride,
				stepMode: l.instanced ? INSTANCE : VERTEX,
				attributes: attributes
			});
		}
		final pipeline_layout = driver.device.createPipelineLayout({
			bindGroupLayouts: desc.layout.map(b -> (cast b : BindGroupLayout).layout)
		});
		pipeline = driver.device.createRenderPipeline({
			vertex: {
				module: (cast desc.vertexShader : Shader).module,
				entryPoint: "main",
				buffers: buffers,
				constants: {}
			},
			layout: pipeline_layout,
			primitive: {
				topology: TRIANGLE_STRIP,
				stripIndexFormat: UINT32,
				frontFace: CCW,
				cullMode: switch desc.culling {
					case None: NONE;
					case Back: BACK;
					case Front: FRONT;
					case Both: FRONT;
				}
			},
			depthStencil: {
				format: DEPTH24PLUS_STENCIL8,
				depthWriteEnabled: desc.depthWrite,
				// depthCompare: depthCompare,
				// stencilFront: stencilFront,
				// stencilBack: stencilBack,
				// stencilReadMask: stencilReadMask,
				// stencilWriteMask: stencilWriteMask,
				// depthBias: depthBias,
				// depthBiasSlopeScale: depthBiasSlopeScale,
				// depthBiasClamp: depthBiasClamp
			},
			// multisample: {
			// 	count: count,
			// 	mask: mask,
			// 	alphaToCoverageEnabled: alphaToCoverageEnabled
			// },
			fragment: {
				module: (cast desc.fragmentShader : Shader).module,
				targets: [
					{
						format: driver.preferredFormat
					}
				],
				entryPoint: "main",
				constants: {}
			}
		});
	}

	public function dispose() {}
}

@:nullSafety(Strict)
private class Shader implements IShaderModule {
	public var desc(default, null):ShaderDescriptor;

	public final module:GPUShaderModule;

	public function new(driver:WGPUDriver, desc:ShaderDescriptor) {
		this.desc = desc;
		final ext = switch desc.module.stage {
			case Vertex: "vert";
			case Fragment: "frag";
			case Compute: "comp";
		}
		module = driver.device.createShaderModule({
			code: haxe.Resource.getString('${desc.module.id}-$ext-webgpu'),
			label: 'arcane-${desc.module.id}'
		});
	}

	public function dispose() {}
}

@:nullSafety(Strict)
private class VertexBuffer implements IVertexBuffer {
	public var desc(default, null):VertexBufferDescriptor;

	public final buffer:GPUBuffer;
	public final buf_stride:Int = 0;

	final driver:WGPUDriver;

	public function new(driver:WGPUDriver, desc:VertexBufferDescriptor) {
		this.desc = desc;
		this.driver = driver;
		var stride = 0;
		for (l in desc.attributes) {
			stride += switch l.kind {
				case Float1: 1 * 4;
				case Float2: 2 * 4;
				case Float3: 3 * 4;
				case Float4: 4 * 4;
				case Float4x4: 16 * 4;
			}
		}
		this.buf_stride = stride;
		buffer = driver.device.createBuffer({
			size: desc.size * buf_stride,
			usage: VERTEX | COPY_DST
		});
	}

	public function dispose() {
		buffer.destroy();
	}

	public function stride():Int {
		return cast buf_stride / 4;
	}

	public function upload(start:Int, arr:ArrayBuffer):Void {
		// var jsarray:ArrayBufferView = (arr : Float32Array);
		driver.device.queue.writeBuffer(buffer, start * buf_stride, cast arr, 0, arr.byteLength);
	}

	public function map(start:Int, range:Int):ArrayBuffer {
		return driver.stagingBuffers.writeBuffer(driver.device, cast driver.encoder, buffer, start * buf_stride, range * buf_stride);
	}

	public function unmap():Void {}
}

@:nullSafety(Strict)
private class IndexBuffer implements IIndexBuffer {
	public var desc(default, null):IndexBufferDescriptor;

	public final buffer:GPUBuffer;

	final driver:WGPUDriver;

	public function new(driver:WGPUDriver, desc:IndexBufferDescriptor) {
		this.desc = desc;
		this.driver = driver;
		buffer = driver.device.createBuffer({
			size: desc.size * 4,
			usage: INDEX | COPY_DST
		});
	}

	public function dispose() {
		buffer.destroy();
	}

	public function upload(start:Int, arr:ArrayBuffer):Void {
		driver.device.queue.writeBuffer(buffer, start * 4, cast arr, 0, arr.byteLength);
	}

	public function map(start:Int, range:Int):ArrayBuffer {
		return driver.stagingBuffers.writeBuffer(driver.device, cast driver.encoder, buffer, start * 4, range * 4);
	}

	public function unmap():Void {}
}

@:nullSafety(Strict)
private class UniformBuffer implements IUniformBuffer {
	public var desc(default, null):UniformBufferDescriptor;

	public final buffer:GPUBuffer;

	final driver:WGPUDriver;

	public function new(driver:WGPUDriver, desc:UniformBufferDescriptor) {
		this.desc = desc;
		this.driver = driver;
		buffer = driver.device.createBuffer({
			size: desc.size,
			usage: UNIFORM | COPY_DST
		});
	}

	public function dispose() {
		buffer.destroy();
	}

	public function upload(start:Int, arr:ArrayBuffer):Void {
		driver.device.queue.writeBuffer(buffer, start, cast arr, 0, arr.byteLength);
	}

	public function map(start:Int, range:Int):ArrayBuffer {
		final result = driver.stagingBuffers.writeBuffer(driver.device, cast driver.encoder, buffer, start, range);
		return result;
	}

	public function unmap():Void {}
}

@:nullSafety(Strict)
private class Texture implements ITexture {
	public var desc(default, null):TextureDescriptor;

	public final texture:GPUTexture;
	public final view:GPUTextureView;

	public final depth:GPUTexture;
	public final depth_view:GPUTextureView;

	final driver:WGPUDriver;

	public function new(driver:WGPUDriver, desc:TextureDescriptor) {
		this.desc = desc;
		this.driver = driver;
		texture = driver.device.createTexture({
			size: {
				width: desc.width,
				height: desc.height,
				depthOrArrayLayers: 1
			},
			format: switch desc.format {
				case RGBA: RGBA8UNORM;
				case BGRA: BGRA8UNORM;
				case ARGB: throw "assert";
			},
			usage: (desc.isRenderTarget ? RENDER_ATTACHMENT : COPY_DST) | TEXTURE_BINDING
		});
		view = texture.createView();
		depth = driver.device.createTexture({
			size: {
				width: desc.width,
				height: desc.width,
				depthOrArrayLayers: 1
			},
			format: DEPTH24PLUS_STENCIL8,
			usage: RENDER_ATTACHMENT
		});
		depth_view = depth.createView();
	}

	public function dispose() {
		texture.destroy();
	}

	public function upload(bytes:haxe.io.Bytes):Void {
		driver.device.queue.writeTexture({texture: texture}, @:privateAccess bytes.b, {}, {width: this.desc.width, height: this.desc.height});
	}
}

@:nullSafety(Strict)
private class Sampler implements ISampler {
	public final sampler:GPUSampler;

	public function new(driver:WGPUDriver, desc:SamplerDescriptor) {
		this.sampler = driver.device.createSampler({
			addressModeU: WGPUDriver.convertAddressMode(desc.uAddressing),
			addressModeV: WGPUDriver.convertAddressMode(desc.uAddressing),
			addressModeW: WGPUDriver.convertAddressMode(desc.wAddressing),
			magFilter: WGPUDriver.convertFilter(desc.magFilter),
			minFilter: WGPUDriver.convertFilter(desc.minFilter),
			mipmapFilter: WGPUDriver.convertMipmapFilter(desc.mipFilter),
			lodMinClamp: desc.lodMinClamp,
			lodMaxClamp: desc.lodMaxClamp,
			compare: desc.compare != null ? WGPUDriver.convertCompareMode(desc.compare) : js.Syntax.code("undefined"),
			maxAnisotropy: desc.maxAnisotropy
		});
	}
}

@:nullSafety(Strict)
private class CommandEncoder implements ICommandEncoder {
	public final encoder:GPUCommandEncoder;

	public function new(driver:WGPUDriver) {
		this.encoder = driver.device.createCommandEncoder();
	}

	public function beginComputePass(desc:ComputePassDescriptor):IComputePass {
		return new ComputePass(encoder, desc);
	}

	public function beginRenderPass(desc:RenderPassDescriptor):IRenderPass {
		return new RenderPass(encoder, desc);
	}

	public function finish():ICommandBuffer {
		return new CommandBuffer(encoder.finish());
	}
}

private class CommandBuffer implements ICommandBuffer {
	public final buffer:GPUCommandBuffer;

	public function new(buffer:GPUCommandBuffer) {
		this.buffer = buffer;
	}
}

@:nullSafety(Strict)
private class RenderPass implements IRenderPass {
	final renderPass:GPURenderPassEncoder;
	final encoder:GPUCommandEncoder;

	public function new(encoder, desc:RenderPassDescriptor) {
		this.encoder = encoder;
		this.renderPass = encoder.beginRenderPass({
			colorAttachments: [
				for (a in desc.colorAttachments)
					{
						view: (cast a.texture : Texture).view,
						loadValue: switch a.load {
							case Clear if (a.loadValue != null): ({
									r: a.loadValue.r / 0xFF,
									g: a.loadValue.g / 0xFF,
									b: a.loadValue.b / 0xFF,
									a: a.loadValue.a / 0xFF
								} : wgpu.GPUColorDict);
							case Clear: {
									r: 0.0,
									g: 0.0,
									b: 0.0,
									a: 1.0
								}
							case Load: null;
						},
						loadOp: switch a.load {
							case Load: LOAD;
							case Clear: CLEAR;
						},
						storeOp: switch a.store {
							case Store: STORE;
							case Discard: DISCARD;
						}
					}
			],
			depthStencilAttachment: {
				view: (cast desc.colorAttachments[0].texture : Texture).depth_view,
				depthLoadValue: 0,
				depthStoreOp: DISCARD,
				stencilLoadValue: 0,
				stencilStoreOp: DISCARD
			}});
	}

	public function setPipeline(p:IRenderPipeline) {
		renderPass.setPipeline((cast p : RenderPipeline).pipeline);
	}

	public function setVertexBuffer(buffer:IVertexBuffer) {
		renderPass.setVertexBuffer(0, (cast buffer : VertexBuffer).buffer);
	}

	public function setVertexBuffers(buffers:Array<IVertexBuffer>) {
		for (i => buffer in buffers)
			renderPass.setVertexBuffer(i, (cast buffer : VertexBuffer).buffer);
	}

	public function setIndexBuffer(buffer:IIndexBuffer) {
		renderPass.setIndexBuffer((cast buffer : IndexBuffer).buffer, buffer.desc.is32 ? UINT32 : UINT16);
	}

	public function setBindGroup(index:Int, group:IBindGroup) {
		renderPass.setBindGroup(index, (cast group : BindGroup).group);
	}

	public function draw(start:Int, count:Int) {
		renderPass.drawIndexed(count, 1, start);
	}

	public function drawInstanced(instanceCount:Int, start:Int, count:Int) {
		renderPass.drawIndexed(count, instanceCount, start);
	}

	public function end() {
		renderPass.endPass();
	}
}

@:nullSafety(Strict)
private class ComputePipeline implements IComputePipeline {
	public var desc(default, null):ComputePipelineDescriptor;

	public final pipeline:GPUComputePipeline;

	public function new(driver:WGPUDriver, desc:ComputePipelineDescriptor) {
		this.desc = desc;
		this.pipeline = driver.device.createComputePipeline({
			compute: {module: (cast desc.shader : Shader).module, entryPoint: "main"},
			layout: "auto"
		});
	}

	public function dispose() {}
}

@:nullSafety(Strict)
private class ComputePass implements IComputePass {
	final pass:GPUComputePassEncoder;
	final encoder:GPUCommandEncoder;

	public function new(encoder:GPUCommandEncoder, desc:ComputePassDescriptor) {
		this.encoder = encoder;
		this.pass = encoder.beginComputePass();
	}

	public function setBindGroup(index:Int, group:IBindGroup) {
		pass.setBindGroup(index, (cast group : BindGroup).group);
	}

	public function setPipeline(p:IComputePipeline) {
		pass.setPipeline((cast p : ComputePipeline).pipeline);
	}

	public function dispatch(x:Int, y:Int, z:Int) {
		pass.dispatchWorkgroups(x, y, z);
	}

	public function end() {
		pass.end();
	}
}

@:nullSafety(Strict)
@:allow(arcane.internal)
class WGPUDriver implements IGPUDevice {
	public final features:DriverFeatures;
	public final limits:DriverLimits;

	#if js
	final canvas:CanvasElement;
	#end
	final context:GPUCanvasContext;
	final adapter:GPUAdapter;
	final device:GPUDevice;
	final preferredFormat:GPUTextureFormat;
	final _getCurrentTexture:() -> GPUTexture;

	/**The texture of the the current swapchain image**/
	var currentTexture:Null<GPUTexture>;

	/**The texture view of the the current swapchain image**/
	var currentTextureView:Null<GPUTextureView>;

	var encoder:Null<GPUCommandEncoder>;

	final stagingBuffers:StagingBuffers;

	public function new(#if js canvas:CanvasElement, #end context:GPUCanvasContext, adapter:GPUAdapter, device:GPUDevice) {
		features = {
			compute: true,
			uintIndexBuffers: true,
			multipleColorAttachments: true,
			flippedRenderTargets: false,
			instancedRendering: true
		};
		limits = {};
		#if js
		this.canvas = canvas;
		#end
		this.context = context;
		this.adapter = adapter;
		this.device = device;
		this.preferredFormat = try (untyped navigator.gpu : wgpu.GPU).getPreferredCanvasFormat() catch (_) try
			untyped context.getPreferredFormat(adapter)
		catch (_)
			untyped context.getSwapChainPreferredFormat(adapter);
		final presentationConfiguration:GPUCanvasConfiguration = {
			device: device,
			format: preferredFormat,
			usage: RENDER_ATTACHMENT
		}
		_getCurrentTexture = try {
			context.configure(presentationConfiguration);
			context.getCurrentTexture;
		} catch (_) {
			final swapChain = untyped context.configureSwapChain(presentationConfiguration);
			swapChain.getCurrentTexture;
		}
		if (device.lost != null)
			device.lost.then(error -> (untyped console).error("WebGPU device lost", error.message, error.reason));
		device.onuncapturederror = (e) -> {
			trace(e);
		}
		// todo : let the user set the chunk_size
		this.stagingBuffers = new StagingBuffers(1024);
		this.encoder = device.createCommandEncoder();
	}

	public function getName(details:Bool = false):String {
		return "WebGPU";
	}

	public function dispose() {
		device.destroy();
		context.unconfigure();
	}

	public function getCurrentTexture():ITexture {
		currentTexture = _getCurrentTexture();
		currentTextureView = @:nullSafety(Off) currentTexture.createView();

		final t:{
			texture:GPUTexture,
			view:GPUTextureView,
			desc:TextureDescriptor,
			depth:GPUTexture,
			depth_view:GPUTextureView
		} = cast Type.createEmptyInstance(Texture);
		t.texture = cast currentTexture;
		t.view = cast currentTextureView;
		t.desc = {
			width: canvas.clientWidth,
			isRenderTarget: true,
			height: canvas.clientHeight,
			format: RGBA,
			data: null
		}
		t.depth = device.createTexture({
			size: [canvas.clientWidth, canvas.clientHeight, 1],
			format: DEPTH24PLUS_STENCIL8,
			usage: RENDER_ATTACHMENT
		});
		t.depth_view = t.depth.createView();
		return cast t;
	}

	public function createVertexBuffer(desc:VertexBufferDescriptor):IVertexBuffer {
		return new VertexBuffer(this, desc);
	}

	public function createIndexBuffer(desc:IndexBufferDescriptor):IIndexBuffer {
		return new IndexBuffer(this, desc);
	}

	public function createUniformBuffer(desc:UniformBufferDescriptor):IUniformBuffer {
		return new UniformBuffer(this, desc);
	}

	public function createTexture(desc:TextureDescriptor):ITexture {
		return new Texture(this, desc);
	}

	public function createSampler(desc:SamplerDescriptor):ISampler {
		return new Sampler(this, desc);
	}

	public function createShader(desc:ShaderDescriptor):IShaderModule {
		return new Shader(this, desc);
	}

	public function createRenderPipeline(desc:RenderPipelineDescriptor):IRenderPipeline {
		return new RenderPipeline(this, desc);
	}

	public function createComputePipeline(desc:ComputePipelineDescriptor):IComputePipeline {
		return new ComputePipeline(this, desc);
	}

	public function createCommandEncoder():ICommandEncoder {
		return new CommandEncoder(this);
	}

	public function createBindGroup(desc:BindGroupDescriptor):IBindGroup {
		var entries:Array<GPUBindGroupEntry> = [];
		for (entry in desc.entries)
			switch entry.resource {
				case Buffer(buffer):
					entries.push({
						binding: entry.binding,
						resource: {buffer: (cast buffer : UniformBuffer).buffer}
					});
				case Texture(texture, sampler):
					entries.push({
						binding: entry.binding,
						resource: (cast texture : Texture).view
					});
					entries.push({
						binding: entry.binding + 1,
						resource: (cast sampler : Sampler).sampler
					});
			}

		return new BindGroup(device.createBindGroup({
			layout: (cast desc.layout : BindGroupLayout).layout,
			entries: entries
		}));
	}

	public function createBindGroupLayout(desc:BindGroupLayoutDescriptor):IBindGroupLayout {
		final entries:Array<GPUBindGroupLayoutEntry> = [];
		for (entry in desc.entries) {
			var e:GPUBindGroupLayoutEntry = {
				binding: entry.binding,
				visibility: cast entry.visibility
			};
			switch entry.kind {
				case Buffer(hasDynamicOffset, minBindingSize):
					entries.push({
						binding: entry.binding,
						visibility: cast entry.visibility,
						buffer: {type: UNIFORM, hasDynamicOffset: hasDynamicOffset, minBindingSize: minBindingSize}
					});
				case Texture(type):
					entries.push({
						binding: entry.binding,
						visibility: cast entry.visibility,
						texture: {
							sampleType: FLOAT,
							viewDimension: _2D,
							multisampled: false
						}
					});
					entries.push({
						binding: entry.binding + 1,
						visibility: cast entry.visibility,
						sampler: {
							type: switch type {
								case Filtering: FILTERING;
								case NonFiltering: NON_FILTERING;
								case Comparison: COMPARISON;
							}
						}
					});
			}
		}

		return new BindGroupLayout(device.createBindGroupLayout({
			entries: entries
		}));
	}

	public function submit(buffers:Array<ICommandBuffer>) @:nullSafety(Off) {
		stagingBuffers.finish();
		device.queue.submit(buffers.map(b -> (cast b : CommandBuffer).buffer).concat([this.encoder.finish()]));
		this.encoder = device.createCommandEncoder({label: "staging encoder"});
		stagingBuffers.recall();
	}

	public function present() {}

	static function convertAddressMode(mode:AddressMode):GPUAddressMode {
		return switch mode {
			case Clamp: CLAMP_TO_EDGE;
			case Repeat: REPEAT;
			case Mirrored: MIRROR_REPEAT;
		}
	}

	static function convertFilter(mode:FilterMode):GPUFilterMode {
		return switch mode {
			case Nearest: NEAREST;
			case Linear: LINEAR;
		}
	}

	static function convertMipmapFilter(mode:FilterMode):GPUMipmapFilterMode {
		return switch mode {
			case Nearest: NEAREST;
			case Linear: LINEAR;
		}
	}

	static function convertCompareMode(mode:Compare):GPUCompareFunction {
		return switch mode {
			case Always: ALWAYS;
			case Never: NEVER;
			case Equal: EQUAL;
			case NotEqual: NOT_EQUAL;
			case Greater: GREATER;
			case GreaterEqual: GREATER_EQUAL;
			case Less: LESS;
			case LessEqual: LESS_EQUAL;
		}
	}
}
#end
