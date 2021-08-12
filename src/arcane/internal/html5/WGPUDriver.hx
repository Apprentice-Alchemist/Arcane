package arcane.internal.html5;

#if wgpu_externs
import wgpu.GPUPipelineLayout;
import js.lib.Uint32Array;
import wgpu.GPUVertexAttribute;
import wgpu.GPUVertexFormat;
import wgpu.GPUVertexBufferLayout;
import wgpu.GPURenderPassEncoder;
import wgpu.GPUCommandEncoder;
import wgpu.GPUBuffer;
import wgpu.GPUShaderModule;
import wgpu.GPURenderPipeline;
import wgpu.GPUTexture;
import wgpu.GPUPresentationConfiguration;
import wgpu.GPUTextureFormat;
import wgpu.GPUDevice;
import wgpu.GPUAdapter;
import wgpu.GPUPresentationContext;
import js.html.CanvasElement;
import arcane.common.arrays.Int32Array;
import arcane.common.arrays.Float32Array;
import arcane.system.IGraphicsDriver;
import arcane.Utils.assert;

using arcane.Utils;

private class TextureUnit implements ITextureUnit {
	public function new() {}
}

private class ConstantLocation implements IConstantLocation {
	public function new() {}
}

private class Pipeline implements IPipeline {
	public var desc(default, null):PipelineDesc;

	public final pipeline:GPURenderPipeline;

	// public final layout:GPUPipelineLayout;
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
						throw "assert";
				}
				attributes.push({
					format: format,
					offset: offset,
					shaderLocation: i++
				});
			}
			buffers.push({
				arrayStride: stride,
				stepMode: l.instanced ? Instance : Vertex,
				attributes: attributes
			});
		}
		// layout = driver.device.createPipelineLayout({
		// 	bindGroupLayouts: []
		// });
		// final bindGroupLayout = driver.device.createBindGroupLayout({
		// 	entries: [
		// 		{
		// 			binding: 0,
		// 			visibility: VERTEX,
		// 			buffer: {type: Uniform, hasDynamicOffset: true},
		// 			sampler: {type: Filtering}
		// 		}
		// 	]
		// });
		// var v = (null:Texture).texture.createView();
		// driver.device.createBindGroup({
		// 	layout: bindGroupLayout,
		// 	entries: [{resource: v,binding: 0}]
		// });
		// driver.device.createSampler()
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
	}

	public function getConstantLocation(name:String):ConstantLocation {
		return new ConstantLocation();
	}

	public function getTextureUnit(name:String):TextureUnit {
		return new TextureUnit();
	}

	public function dispose() {}
}

private class Shader implements IShader {
	public var desc(default, null):ShaderDesc;

	public final module:GPUShaderModule;

	public function new(driver:WGPUDriver, desc:ShaderDesc) {
		this.desc = desc;
		module = driver.device.createShaderModule(({
			code: new Uint32Array(haxe.Resource.getBytes('${desc.id}-${desc.kind == Vertex ? "vert" : "frag"}-webgpu').getData()),
			label: 'arcane-${desc.id}'
		} : wgpu.GPUShaderModuleDescriptorSPIRV));
	}

	public function dispose() {}
}

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
			usage: VERTEX,
			mappedAtCreation: true
		});
	}

	public function dispose() {
		buffer.destroy();
	}

	public function stride():Int {
		return cast buf_stride / 4;
	}

	// static final mutex = js.Syntax.construct(untyped SharedArrayBuffer, 1); // (untyped new SharedArrayBuffer(1));

	public function upload(start:Int, arr:Float32Array):Void {
		// buffer.mapAsync(WRITE).then(_ -> {
		new js.lib.Float32Array(buffer.getMappedRange()).set(cast arr);
		buffer.unmap();
		// untyped Atomics.wait(mutex, 0);
		// });
		// driver.device.queue.writeBuffer(buffer, 0, arr, 0, buf_stride * desc.size);
	}

	public function map(start:Int, range:Int):Float32Array {
		return new Float32Array(range == -1 ? (desc.size * stride()) - start : range);
	}

	public function unmap():Void {}
}

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

	public function dispose() {}

	public function upload(start:Int, arr:Int32Array):Void {
		driver.device.queue.writeBuffer(buffer, 0, arr);
	}

	public function map(start:Int, range:Int):Int32Array {
		return new Int32Array(range == -1 ? desc.size - start : range);
	}

	public function unmap():Void {}
}

private class Texture implements ITexture {
	public var desc(default, null):TextureDesc;

	public final texture:GPUTexture;

	public function new(driver:WGPUDriver, desc:TextureDesc) {
		this.desc = desc;
		texture = driver.device.createTexture({
			size: {
				width: desc.width,
				height: desc.height,
				depth: 0
			},
			format: switch desc.format {
				case RGBA: RGBA8UNORM;
				case BGRA: BGRA8UNORM;
				case ARGB: throw "assert";
			},
			usage: COPY_DST
		});
	}

	public function dispose() {
		texture.destroy();
	}

	public function upload(bytes:haxe.io.Bytes):Void {}
}

private class RenderPass implements IRenderPass {
	public final renderPass:GPURenderPassEncoder;

	final driver:WGPUDriver;
	final encoder:GPUCommandEncoder;

	public function new(driver:WGPUDriver, desc:RenderPassDesc) {
		this.driver = driver;
		this.encoder = driver.encoder == null ? (throw "assert") : driver.encoder;
		this.renderPass = encoder.beginRenderPass({
			colorAttachments: [
				for (a in desc.colorAttachments)
					{
						view: a.texture == null ? driver.getCurrentTexture().createView() : (cast a.texture : Texture).texture.createView(),
						loadValue: switch a.load {
							case Clear: {
									r: a.loadValue.r / 0xFF,
									g: a.loadValue.g / 0xFF,
									b: a.loadValue.b / 0xFF,
									a: a.loadValue.a / 0xFF
								};
							case Load: "load";
						},
						storeOp: switch a.store {
							case Store: Store;
							case Discard: Discard;
						}
					}
			]});
	}

	public function setPipeline(p:IPipeline) {
		renderPass.setPipeline((cast p : Pipeline).pipeline);
	}

	public function setVertexBuffer(buffer:IVertexBuffer) {
		renderPass.setVertexBuffer(0, (cast buffer : VertexBuffer).buffer);
	}

	public function setVertexBuffers(buffers:Array<IVertexBuffer>) {
		assert(renderPass != null);
		final renderPass:GPURenderPassEncoder = renderPass;
		for (i => buffer in buffers)
			renderPass.setVertexBuffer(i, (cast buffer : VertexBuffer).buffer);
	}

	public function setIndexBuffer(buffer:IIndexBuffer) {
		renderPass.setIndexBuffer((cast buffer : IndexBuffer).buffer, buffer.desc.is32 ? UInt32 : UInt16);
	}

	public function setTextureUnit(t:ITextureUnit, tex:ITexture) {}

	public function setConstantLocation(l:IConstantLocation, f:Float32Array) {}

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

@:allow(arcane.internal)
class WGPUDriver implements IGraphicsDriver {
	public final renderTargetFlipY:Bool = false;
	public final instancedRendering:Bool = true;
	public final uintIndexBuffers:Bool = true;

	final canvas:CanvasElement;
	final context:GPUPresentationContext;
	final adapter:GPUAdapter;
	final device:GPUDevice;
	final preferredFormat:GPUTextureFormat;
	final getCurrentTexture:() -> GPUTexture;

	var encoder:Null<GPUCommandEncoder>;

	public function new(canvas:CanvasElement, context:GPUPresentationContext, adapter:GPUAdapter, device:GPUDevice) {
		untyped console.log(canvas, context, adapter, device);
		this.canvas = canvas;
		this.context = context;
		this.adapter = adapter;
		this.device = device;

		this.preferredFormat = try context.getPreferredFormat(adapter) catch (_) untyped context.getSwapChainPreferredFormat(adapter);
		final presentationConfiguration:GPUPresentationConfiguration = {
			device: device,
			format: preferredFormat,
			usage: RENDER_ATTACHMENT
		}
		getCurrentTexture = try {
			context.configure(presentationConfiguration);
			context.getCurrentTexture;
		} catch (_) {
			final swapChain:wgpu.GPUSwapChain = untyped context.configureSwapChain(presentationConfiguration);
			swapChain.getCurrentTexture;
		}
		device.lost.then(error -> (untyped console).error("WebGPU device lost", error.message, error.reason));
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

	public function begin() {
		encoder = device.createCommandEncoder();
	}

	public function clear(?col:arcane.common.Color, ?depth:Float, ?stencil:Int) {}

	public function end() {
		device.queue.submit([encoder.sure().finish()]);
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

	public function beginRenderPass(desc:RenderPassDesc) {
		return new RenderPass(this,desc);
	}
}
#end
