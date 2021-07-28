package arcane.internal.html5;

#if wgpu_externs
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

private class TextureUnit implements ITextureUnit {
	public function new() {}
}

private class ConstantLocation implements IConstantLocation {
	public function new() {}
}

private class Pipeline implements IPipeline {
	public var desc(default, null):PipelineDesc;

	public final pipeline:GPURenderPipeline;

	public function new(driver:WGPUDriver, desc:PipelineDesc) {
		this.desc = desc;
		var buffers:Array<GPUVertexBufferLayout> = [];
		for (l in desc.inputLayout) {
			var stride = 0;
			var attributes:Array<GPUVertexAttribute> = [];
			for (i => attribute in l.attributes) {
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
					shaderLocation: i
				});
			}
			buffers.push({
				arrayStride: stride,
				stepMode: l.instanced ? Instance : Vertex,
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
			code: new Uint32Array(haxe.Resource.getBytes('${desc.id}-${desc.kind == Vertex ? "vert" : "frag"}-webgpu').getData())
		} : wgpu.GPUShaderModuleDescriptorSPIRV));
	}

	public function dispose() {}
}

private class VertexBuffer implements IVertexBuffer {
	public var desc(default, null):VertexBufferDesc;

	public final buffer:GPUBuffer;
	public final stride:Int = 0;

	final driver:WGPUDriver;

	public function new(driver:WGPUDriver, desc:VertexBufferDesc) {
		this.desc = desc;
		this.driver = driver;
		var stride = 0;
		for (l in desc.attributes)
			stride += switch l.kind {
				case Float1: 1 * 4;
				case Float2: 2 * 4;
				case Float3: 3 * 4;
				case Float4: 4 * 4;
				case Float4x4: 16 * 4;
			}
		this.stride = stride;
		buffer = driver.device.createBuffer({
			size: desc.size * stride,
			usage: VERTEX | COPY_DST
		});
	}

	public function dispose() {
		buffer.destroy();
	}

	public function upload(start:Int, arr:Float32Array):Void {
		driver.device.queue.writeBuffer(buffer, 0, arr);
	}

	public function map(start:Int, range:Int):Float32Array {
		return new Float32Array(range == -1 ? (desc.size * stride) - start : range);
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
	var renderPass:Null<GPURenderPassEncoder>;

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
		renderPass = encoder.beginRenderPass({
			colorAttachments: [
				{
					view: getCurrentTexture().createView(),
					loadValue: {
						r: 0.0,
						g: 0.0,
						b: 0.0,
						a: 1.0
					},
					storeOp: Store
				}
			]
		});
	}

	public function clear(?col:arcane.common.Color, ?depth:Float, ?stencil:Int) {}

	public function end() {
		renderPass.sure().endPass();
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

	public function setRenderTarget(?t:ITexture) {}

	public function setPipeline(p:IPipeline) {
		renderPass.sure().setPipeline((cast p : Pipeline).pipeline);
	}

	public function setVertexBuffer(buffer:IVertexBuffer) {
		renderPass.sure().setVertexBuffer(0, (cast buffer : VertexBuffer).buffer);
	}

	public function setVertexBuffers(buffers:Array<IVertexBuffer>) {
		for (i => buffer in buffers)
			renderPass.sure().setVertexBuffer(i, (cast buffer : VertexBuffer).buffer);
	}

	public function setIndexBuffer(buffer:IIndexBuffer) {
		renderPass.sure().setIndexBuffer((cast buffer : IndexBuffer).buffer, buffer.desc.is32 ? UInt32 : UInt16);
	}

	public function setTextureUnit(t:ITextureUnit, tex:ITexture) {}

	public function setConstantLocation(l:IConstantLocation, f:Float32Array) {}

	public function draw(start:Int, count:Int) {
		renderPass.sure().drawIndexed(count, 1, start);
	}

	public function drawInstanced(instanceCount:Int, start:Int, count:Int) {
		renderPass.sure().drawIndexed(count, instanceCount, start);
	}
}
#end