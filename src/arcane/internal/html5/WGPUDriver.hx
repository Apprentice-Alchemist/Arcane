package arcane.internal.html5;

#if wgpu_externs
import js.lib.ArrayBuffer;
import arcane.common.arrays.Float32Array;
import arcane.common.arrays.Int32Array;
import arcane.system.IGraphicsDriver;
import js.html.CanvasElement;
import js.lib.Uint32Array;
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
		inline function swap_remove(arr:Array<BufferChunk>, i:Int):Void @:nullSafety(Off) {
			if (arr.length == 1) {
				arr.pop();
			} else {
				arr[i] = arr.pop();
			}
		}
		for (i => c in active_chunks) {
			if (c.offset + size <= c.size) {
				chunk = active_chunks[i];
				swap_remove(active_chunks, i);
				break;
			}
		}
		if (chunk == null) {
			for (i => c in free_chunks) {
				if (size <= c.size) {
					chunk = free_chunks[i];
					swap_remove(free_chunks, i);
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
			size: size,
			offset: 0
		} else chunk;
		encoder.copyBufferToBuffer(chunk.buffer, chunk.offset, target, offset, size);
		final old_offset = chunk.offset;
		chunk.offset += size;
		final remainder = chunk.offset % 8;
		if (remainder != 0)
			chunk.offset += 8 - remainder;
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
			chunk.buffer.mapAsync(WRITE).then(_ -> free_chunks.push(chunk)).catchError(e -> (untyped console).error(e));
		}
	}
}

@:nullSafety(Strict)
private class TextureUnit implements ITextureUnit {
	public function new() {}
}

@:nullSafety(Strict)
private class ConstantLocation implements IConstantLocation {
	public function new() {}
}

@:nullSafety(Strict)
private class Pipeline implements IPipeline {
	public var desc(default, null):PipelineDesc;

	public final pipeline:GPURenderPipeline;

	public final layout:GPUBindGroupLayout;

	final driver:WGPUDriver;

	public function new(driver:WGPUDriver, desc:PipelineDesc) {
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

		pipeline = driver.device.createRenderPipeline({
			vertex: {
				buffers: buffers,
				module: (cast desc.vertexShader : Shader).module,
				entryPoint: "main",
				constants: {}
			},
			fragment: {
				targets: [
					{
						format: driver.preferredFormat
					}
				],
				module: (cast desc.fragmentShader : Shader).module,
				entryPoint: "main"
			}
		});
		layout = pipeline.getBindGroupLayout(0);
	}

	public function getConstantLocation(name:String):ConstantLocation {
		return new ConstantLocation();
	}

	public function getTextureUnit(name:String):TextureUnit {
		return new TextureUnit();
	}

	public function dispose() {}
}

@:nullSafety(Strict)
private class Shader implements IShader {
	public var desc(default, null):ShaderDesc;

	public final module:GPUShaderModule;

	public function new(driver:WGPUDriver, desc:ShaderDesc) {
		this.desc = desc;
		module = driver.device.createShaderModule({
			code: cast new Uint32Array(haxe.Resource.getBytes('${desc.id}-${desc.kind == Vertex ? "vert" : "frag"}-webgpu').getData()),
			label: 'arcane-${desc.id}'
		});
	}

	public function dispose() {}
}

@:nullSafety(Strict)
private class VertexBuffer implements IVertexBuffer {
	public var desc(default, null):VertexBufferDesc;

	public final buffer:GPUBuffer;
	public final buf_stride:Int = 0;

	final driver:WGPUDriver;

	public function new(driver:WGPUDriver, desc:VertexBufferDesc) {
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
		trace(stride, buf_stride, desc.size, buf_stride * desc.size);
		buffer = driver.device.createBuffer({
			size: desc.size * buf_stride,
			usage: VERTEX | COPY_DST,
			mappedAtCreation: true
		});
	}

	public function dispose() {
		buffer.destroy();
	}

	public function stride():Int {
		return cast buf_stride / 4;
	}

	public function upload(start:Int, arr:Float32Array):Void {
		new js.lib.Float32Array(buffer.getMappedRange()).set(cast arr);
		buffer.unmap();
		driver.device.queue.writeBuffer(buffer, start * buf_stride, cast arr, 0, (cast arr : js.lib.Float32Array).byteLength);
	}

	public function map(start:Int, range:Int):Float32Array {
		final result = driver.stagingBuffers.writeBuffer(driver.device, cast driver.encoder, buffer, start * buf_stride, range * buf_stride);
		return cast new js.lib.Float32Array(result);
	}

	public function unmap():Void {}
}

@:nullSafety(Strict)
private class IndexBuffer implements IIndexBuffer {
	public var desc(default, null):IndexBufferDesc;

	public final buffer:GPUBuffer;

	final driver:WGPUDriver;

	public function new(driver:WGPUDriver, desc:IndexBufferDesc) {
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

	public function upload(start:Int, arr:Int32Array):Void {
		driver.device.queue.writeBuffer(buffer, 0, cast arr);
	}

	public function map(start:Int, range:Int):Int32Array {
		final result = driver.stagingBuffers.writeBuffer(driver.device, cast driver.encoder, buffer, start * 4, range * 4);
		return cast new js.lib.Int32Array(result);
	}

	public function unmap():Void {}
}

@:nullSafety(Strict)
private class Texture implements ITexture {
	public var desc(default, null):TextureDesc;

	public final texture:GPUTexture;
	public final view:GPUTextureView;

	final driver:WGPUDriver;

	public function new(driver:WGPUDriver, desc:TextureDesc) {
		this.desc = desc;
		this.driver = driver;
		texture = driver.device.createTexture({
			size: {
				width: desc.width,
				height: desc.height,
				depthOrArrayLayers: 0
			},
			format: switch desc.format {
				case RGBA: RGBA8UNORM;
				case BGRA: BGRA8UNORM;
				case ARGB: throw "assert";
			},
			usage: (desc.isRenderTarget ? RENDER_ATTACHMENT : COPY_DST) | TEXTURE_BINDING
		});
		view = texture.createView();
	}

	public function dispose() {
		texture.destroy();
	}

	public function upload(bytes:haxe.io.Bytes):Void {
		driver.device.queue.writeTexture({texture: texture}, @:privateAccess bytes.b, {}, {width: this.desc.width, height: this.desc.height});
	}
}

@:nullSafety(Strict)
private class RenderPass implements IRenderPass {
	public final renderPass:GPURenderPassEncoder;

	final driver:WGPUDriver;
	final encoder:GPUCommandEncoder;

	public function new(driver:WGPUDriver, desc:RenderPassDesc) {
		this.driver = driver;
		this.encoder = cast driver.encoder == null ? (throw "assert") : driver.encoder;
		this.renderPass = encoder.beginRenderPass({
			colorAttachments: [
				for (a in desc.colorAttachments)
					{
						view: a.texture == null ? cast driver.currentTextureView : (cast a.texture : Texture).texture.createView(),
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
							case Load: "load";
						},
						storeOp: switch a.store {
							case Store: STORE;
							case Discard: DISCARD;
						}
					}
			]});
	}

	var curPipeline:Pipeline = cast null;

	public function setPipeline(p:IPipeline) {
		curPipeline = cast p;
		renderPass.setPipeline((cast p : Pipeline).pipeline);
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

	public function setTextureUnit(t:ITextureUnit, tex:ITexture) {}

	public function setConstantLocation(l:IConstantLocation, f:Float32Array) {
		var f:js.lib.Float32Array = cast f;
		renderPass.setBindGroup(0, driver.device.createBindGroup({
			layout: curPipeline.pipeline.getBindGroupLayout(0),
			entries: [
				{
					binding: 0,
					resource: {
						buffer: {
							var buf = driver.device.createBuffer({
								size: f.byteLength,
								usage: UNIFORM,
								mappedAtCreation: true
							});
							new js.lib.Float32Array(buf.getMappedRange()).set(f);
							buf.unmap();
							buf;
						}
					}
				}
			]
		}));
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
	public var desc(default, null):ComputePipelineDesc;

	final pipeline:GPUComputePipeline;

	public function new(driver:WGPUDriver, desc:ComputePipelineDesc) {
		this.desc = desc;
		this.pipeline = driver.device.createComputePipeline({
			compute: cast null
		});
	}

	public function dispose() {}
}

@:nullSafety(Strict)
private class ComputePass implements IComputePass {
	final pass:GPUComputePassEncoder;
	final encoder:GPUCommandEncoder;

	public function new(driver:WGPUDriver, desc:ComputePassDesc) {
		this.encoder = cast driver.encoder == null ? (throw "assert") : driver.encoder;
		this.pass = encoder.beginComputePass();
	}

	public function setPipeline(p:IComputePipeline) {}

	public function compute(x:Int, y:Int, z:Int) {
		pass.dispatch(x, y, z);
	}
}

@:nullSafety(Strict)
@:allow(arcane.internal)
class WGPUDriver implements IGraphicsDriver {
	final canvas:CanvasElement;
	final context:GPUCanvasContext;
	final adapter:GPUAdapter;
	final device:GPUDevice;
	final preferredFormat:GPUTextureFormat;
	final getCurrentTexture:() -> GPUTexture;

	/**The texture of the the current swapchain image**/
	var currentTexture:Null<GPUTexture>;

	/**The texture view of the the current swapchain image**/
	var currentTextureView:Null<GPUTextureView>;

	var encoder:Null<GPUCommandEncoder>;

	final stagingBuffers:StagingBuffers;

	public function new(canvas:CanvasElement, context:GPUCanvasContext, adapter:GPUAdapter, device:GPUDevice) {
		this.canvas = canvas;
		this.context = context;
		this.adapter = adapter;
		this.device = device;

		this.preferredFormat = try context.getPreferredFormat(adapter) catch (_) untyped context.getSwapChainPreferredFormat(adapter);
		final presentationConfiguration:GPUCanvasConfiguration = {
			device: device,
			format: preferredFormat,
			usage: RENDER_ATTACHMENT
		}
		getCurrentTexture = try {
			context.configure(presentationConfiguration);
			context.getCurrentTexture;
		} catch (_) {
			final swapChain = untyped context.configureSwapChain(presentationConfiguration);
			swapChain.getCurrentTexture;
		}
		device.lost.then(error -> (untyped console).error("WebGPU device lost", error.message, error.reason));
		// todo : let the user set the chunk_size
		this.stagingBuffers = new StagingBuffers(1024);
		
		this.encoder = device.createCommandEncoder();
	}

	public function hasFeature(f:Feature):Bool {
		return switch f {
			case ComputeShaders: true;
			case UintIndexBuffers: true;
			case MultiRenderTargets: true;
			case FlippedRenderTarget: false;
		}
	}

	public function getName(details:Bool = false):String {
		if (details) {
			return "WebGPU : " + adapter.name;
		} else {
			return "WebGPU";
		}
	}

	public function dispose() {
		device.destroy();
		context.unconfigure();
	}

	public function begin():ITexture {
		currentTexture = getCurrentTexture();
		currentTextureView = @:nullSafety(Off) currentTexture.createView();

		final t:{texture:GPUTexture, view:GPUTextureView, desc:TextureDesc} = cast Type.createEmptyInstance(Texture);
		t.texture = getCurrentTexture();
		t.view = t.texture.createView();
		t.desc = {
			width: canvas.clientWidth,
			isRenderTarget: true,
			height: canvas.clientHeight,
			format: RGBA,
			data: null
		}
		return cast t;
	}

	public function end() {
		stagingBuffers.finish();
		if (encoder != null) {
			final buffer = encoder.finish();
			device.queue.submit([buffer]);
		}
		stagingBuffers.recall();
		encoder = device.createCommandEncoder();
	}

	public function flush() {}

	public function present() {}

	public function createVertexBuffer(desc:VertexBufferDesc):IVertexBuffer {
		return new VertexBuffer(this, desc);
	}

	public function createIndexBuffer(desc:IndexBufferDesc):IIndexBuffer {
		return new IndexBuffer(this, desc);
	}

	public function createTexture(desc:TextureDesc):ITexture {
		return new Texture(this, desc);
	}

	public function createShader(desc:ShaderDesc):IShader {
		return new Shader(this, desc);
	}

	public function createPipeline(desc:PipelineDesc):IPipeline {
		return new Pipeline(this, desc);
	}

	public function createComputePipeline(desc:ComputePipelineDesc):IComputePipeline {
		return new ComputePipeline(this, desc);
	}

	public function beginRenderPass(desc:RenderPassDesc) {
		return new RenderPass(this, desc);
	}

	public function beginComputePass(desc:ComputePassDesc):IComputePass {
		return new ComputePass(this, desc);
	}
}
#end
