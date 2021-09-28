package arcane.internal.kinc;

import haxe.ds.ReadOnlyArray;
import kinc.compute.ComputeShader;
import arcane.arrays.ArrayBuffer;
import arcane.system.IGraphicsDriver;
import kinc.g4.Graphics4;
import kinc.g4.Pipeline.StencilAction;
import kinc.g4.RenderTarget;
import arcane.arrays.Float32Array;
import arcane.arrays.Int32Array;
import arcane.Utils.assert;
import arcane.util.Log;

private enum Command {
	BeginRenderPass(desc:RenderPassDescriptor);
	EndRenderPass;
	SetVertexBuffers(b:Array<VertexBuffer>);
	SetIndexBuffer(b:IndexBuffer);
	SetPipeline(p:RenderPipeline);
	SetBindGroup(index:Int, b:BindGroup);
	Draw(start:Int, count:Int);
	DrawInstanced(instanceCount:Int, start:Int, count:Int);

	BeginComputePass(desc:ComputePassDescriptor);
	SetComputePipeline(p:ComputePipeline);
	Compute(x:Int, y:Int, z:Int);
	EndComputePass;
}

class VertexBuffer implements IVertexBuffer {
	public var desc(default, null):VertexBufferDescriptor;

	public var buf:kinc.g4.VertexBuffer;
	public var struc:kinc.g4.VertexStructure;

	public function new(desc:VertexBufferDescriptor) {
		this.desc = desc;
		var struc = new kinc.g4.VertexStructure();
		for (attribute in desc.attributes) {
			struc.add(attribute.name, switch attribute.kind {
				case Float1: Float1;
				case Float2: Float2;
				case Float3: Float3;
				case Float4: Float4;
				case Float4x4: Float4X4;
			});
		}
		this.buf = new kinc.g4.VertexBuffer(desc.size, struc, desc.dyn ? DynamicUsage : StaticUsage, desc.instanceDataStepRate);
		this.struc = struc;
	}

	public function stride():Int {
		assert(buf != null, "Buffer was disposed");
		return buf.stride();
	}

	public function upload(start:Int, arr:Float32Array) {
		assert(buf != null, "Buffer was disposed");
		assert(start + arr.length <= buf.stride() * desc.size, "Trying to upload vertex data outside of buffer bounds!");
		var v = @:nullSafety(Off) buf.lockAll();
		assert(v != null);
		assert(arr != null);
		assert(arr.length > 0);
		// trace(v, arr.length);
		for (i in 0...arr.length)
			v[i] = arr[i];
		@:nullSafety(Off) buf.unlockAll();
	}

	private var last_range:Int = -1;

	public function map(start:Int, range:Int):Float32Array {
		assert(buf != null);
		last_range = range == -1 ? desc.size * buf.stride() : range;
		var r:ArrayBuffer = untyped $new(ArrayBuffer);
		r.byteLength = last_range;
		r.b = @:nullSafety(Off) (buf.lock(start, last_range) : hl.Bytes);
		return cast r;
	}

	public function unmap():Void {
		assert(buf != null);
		assert(last_range != -1);
		buf.unlock(last_range);
	}

	public function dispose() {
		buf.destroy();
		struc.destroy();
	}
}

class IndexBuffer implements IIndexBuffer {
	public var desc(default, null):IndexBufferDescriptor;

	public final buf:kinc.g4.IndexBuffer;

	public function new(desc:IndexBufferDescriptor) {
		this.desc = desc;
		// 16 bit buffers are broken in kinc
		this.buf = new kinc.g4.IndexBuffer(desc.size, IbFormat32BIT /*desc.is32 ? IbFormat32BIT : IbFormat16BIT*/);
	}

	public function upload(start:Int, arr:Int32Array) {
		assert(buf != null, "Buffer disposed");
		assert(start + arr.length <= desc.size, "Trying to upload index data outside of buffer bounds!");
		var x:hl.BytesAccess<Int> = buf.lock();
		for (i in 0...arr.length)
			x[i + start] = arr[i];
		@:nullSafety(Off) buf.unlock();
	}

	public function map(start:Int, range:Int):Int32Array {
		assert(buf != null);
		if (range == -1)
			range = desc.size;
		return cast ArrayBuffer.fromBytes((buf.lock() : hl.Bytes).offset(start >> 2), range);
		// return cast (buf.lock() : hl.Bytes).offset(start >> 2).toBytes(range);
	}

	public function unmap():Void {
		assert(buf != null);
		buf.unlock();
	}

	public function dispose() {
		buf.destroy();
	}
}

private class UniformBuffer implements IUniformBuffer {
	public var desc(default, null):UniformBufferDescriptor;

	final data:ArrayBuffer;

	public function new(descriptor) {
		this.desc = descriptor;
		this.data = new ArrayBuffer(desc.size);
	}

	public function dispose() {}

	public function upload(start:Int, arr:ArrayBuffer) {
		this.data.blit(start, arr, 0, arr.byteLength);
	}

	var last_data:Null<ArrayBuffer> = null;
	var last_start:Null<Int> = null;

	public function map(start:Int, range:Int):ArrayBuffer {
		last_start = start;
		return last_data = new ArrayBuffer(range);
	}

	public function unmap() {
		if (last_data != null) {
			this.data.blit(cast last_start, cast last_data, 0, (cast last_data).byteLength);
		}
	}
}

@:nullSafety(Strict)
class Texture implements ITexture {
	public var desc(default, null):TextureDescriptor;

	public final tex:Null<kinc.g4.Texture>;
	public final renderTarget:Null<kinc.g4.RenderTarget>;

	public function new(desc:TextureDescriptor) {
		this.desc = desc;

		if (desc.isRenderTarget) {
			renderTarget = RenderTarget.create(desc.width, desc.height, 24, false, Format32Bit, 8, 0);
		} else {
			var tex = new kinc.g4.Texture();
			this.tex = tex;
			tex.init(desc.width, desc.height, switch desc.format {
				case RGBA: FORMAT_RGBA32;
				case BGRA: FORMAT_BGRA32;
				case ARGB: throw "assert";
			});
			if (desc.data != null)
				upload(desc.data);
			// tex.generateMipmaps(9);
		}
	}

	public function upload(data:haxe.io.Bytes):Void {
		assert(!desc.isRenderTarget && tex != null);
		if (tex != null)
			@:nullSafety(Off) {
			var t = tex.lock();
			var stride = tex.stride();
			for (y in 0...desc.height) {
				for (x in 0...desc.width) {
					t[y * stride + x * 4 + 0] = data.get((y * desc.width + x) * 4 + 0);
					t[y * stride + x * 4 + 1] = data.get((y * desc.width + x) * 4 + 1);
					t[y * stride + x * 4 + 2] = data.get((y * desc.width + x) * 4 + 2);
					t[y * stride + x * 4 + 3] = data.get((y * desc.width + x) * 4 + 4);
				}
			}
			tex.unlock();
		}
	}

	public function dispose():Void {
		if (tex != null)
			tex.destroy();
		if (renderTarget != null)
			renderTarget.destroy();
	}
}

class Shader implements IShaderModule {
	public var desc(default, null):ShaderDescriptor;

	public final shader:Null<kinc.g4.Shader>;
	public final compute:Null<kinc.compute.ComputeShader>;

	public function new(desc:ShaderDescriptor) {
		this.desc = desc;
		var bytes = haxe.Resource.getBytes('${desc.id}-${desc.kind == Vertex ? "vert" : "frag"}-default');
		// #if krafix
		// 	if (desc.fromGlslSrc) {
		// 		var len , out = new hl.Bytes(1024 * 1024);
		// 		compileShader(@:privateAccess bytes.toString().toUtf8(), out, len, switch kinc.System.getGraphicsApi() {
		// 			case D3D9: "d3d9";
		// 			case D3D11: "d3d11";
		// 			case D3D12: "d3d11";
		// 			case OpenGL: "essl";
		// 			case Metal: "metal";
		// 			case Vulkan: "vulkan";
		// 		}, switch Sys.systemName().toLowerCase() {
		// 			case "windows": "windows";
		// 			case "linux": "linux";
		// 			case "mac": "mac";
		// 			case _: throw "unsupported system";
		// 		}, switch desc.kind {
		// 			case Vertex: "vert";
		// 			case Fragment: "frag";
		// 		});
		// 		bytes = out.toBytes(len);
		// 	}
		// #end
		if (desc.kind == Compute) {
			compute = new ComputeShader(bytes);
			shader = null;
		} else {
			compute = null;
			shader = kinc.g4.Shader.create(bytes, switch desc.kind {
				case Fragment: FragmentShader;
				case Vertex: VertexShader;
				case _: throw "unsupported";
			});
		}
	}

	public function dispose():Void {
		if (shader != null)
			shader.destroy();
		if (compute != null)
			compute.destroy();
	}

	// #if krafix
	// @:hlNative("krafix", "compile_shader")
	// static function compileShader(src:hl.Bytes, out:hl.Bytes, outlen:hl.Ref<Int>, targetlang:String, system:String, type:String) {}
	// #end
}

class BindGroupLayout implements IBindGroupLayout {
	final desc:BindGroupLayoutDescriptor;

	public function new(desc:BindGroupLayoutDescriptor) {
		this.desc = desc;
	}
}

class BindGroup implements IBindGroup {
	final desc:BindGroupDescriptor;

	public function new(desc:BindGroupDescriptor) {
		this.desc = desc;
	}
}

class RenderPipeline implements IRenderPipeline {
	public var desc(default, null):RenderPipelineDescriptor;

	public final state:kinc.g4.Pipeline;

	public function new(desc:RenderPipelineDescriptor) {
		this.desc = desc;
		state = new kinc.g4.Pipeline();

		assert(desc.vertexShader.desc.kind == Vertex);
		assert(desc.fragmentShader.desc.kind == Fragment);

		state.vertex_shader = cast cast(desc.vertexShader, Shader).shader;
		state.fragment_shader = cast cast(desc.fragmentShader, Shader).shader;

		for (idx => el in desc.inputLayout) {
			var struc = new kinc.g4.VertexStructure();
			struc.instanced = el.instanced;
			for (attribute in el.attributes) {
				struc.add(attribute.name, switch attribute.kind {
					case Float1: Float1;
					case Float2: Float2;
					case Float3: Float3;
					case Float4: Float4;
					case Float4x4: Float4X4;
				});
			}
			state.input_layout[idx] = struc;
		}

		state.stencil_reference_value = desc.stencil.reference;
		state.stencil_read_mask = desc.stencil.readMask;
		state.stencil_write_mask = desc.stencil.writeMask;
		state.stencil_mode = convertCompare(desc.stencil.frontTest);
		state.stencil_fail = convertStencilOp(desc.stencil.frontSTfail);
		state.stencil_depth_fail = convertStencilOp(desc.stencil.frontDPfail);
		state.stencil_both_pass = convertStencilOp(desc.stencil.frontPass);

		state.cull_mode = switch desc.culling {
			case None: NOTHING;
			case Back: COUNTER_CLOCKWISE;
			case Front: CLOCKWISE;
			case Both: throw "assert";
		}

		state.depth_write = desc.depthWrite;
		state.depth_mode = convertCompare(desc.depthTest);

		state.blend_source = convertBlend(desc.blend.src);
		state.alpha_blend_source = convertBlend(desc.blend.alphaSrc);
		state.alpha_blend_destination = convertBlend(desc.blend.alphaDst);
		state.blend_destination = convertBlend(desc.blend.dst);
		state.compile();
	}

	private static inline function convertBlend(b:Blend):kinc.g4.Pipeline.BlendingOperation {
		return switch b {
			case One: ONE;
			case Zero: ZERO;
			case SrcAlpha: SOURCE_ALPHA;
			case SrcColor: SOURCE_COLOR;
			case DstAlpha: DEST_ALPHA;
			case DstColor: DEST_COLOR;
			case OneMinusSrcAlpha: INV_SOURCE_ALPHA;
			case OneMinusSrcColor: INV_SOURCE_COLOR;
			case OneMinusDstAlpha: INV_DEST_ALPHA;
			case OneMinusDstColor: INV_DEST_COLOR;
		}
	}

	private static inline function convertStencilOp(c:StencilOp):StencilAction {
		return switch c {
			case Keep: KEEP;
			case Zero: ZERO;
			case Replace: REPLACE;
			case Increment: INCREMENT;
			case IncrementWrap: INCREMENT_WRAP;
			case Decrement: DECREMENT;
			case DecrementWrap: DECREMENT_WRAP;
			case Invert: INVERT;
		}
	}

	private static inline function convertCompare(c:Compare):kinc.g4.Pipeline.CompareMode {
		return switch c {
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

	public function dispose():Void {
		state.destroy();
	}
}

private class ComputePipeline implements IComputePipeline {
	public var desc(default, null):ComputePipelineDescriptor;

	public final shader:ComputeShader;

	public function new(desc:ComputePipelineDescriptor) {
		this.desc = desc;
		this.shader = cast(cast desc.shader : Shader).compute;
	}

	public function dispose() {}
}

private class ComputePass implements IComputePass {
	final encoder:CommandEncoder;

	public function new(encoder:CommandEncoder, desc:ComputePassDescriptor) {
		this.encoder = encoder;
	}

	public function setPipeline(p:IComputePipeline) {
		encoder.write(SetComputePipeline(cast p));
	}

	public function dispatch(x:Int, y:Int, z:Int) {
		encoder.write(Command.Compute(x, y, z));
	}

	public function setBindGroup(index:Int, group:IBindGroup) {
		encoder.write(SetBindGroup(index, cast group));
	}
}

private class RenderPass implements IRenderPass {
	final encoder:CommandEncoder;

	public function new(encoder:CommandEncoder, desc:RenderPassDescriptor) {
		this.encoder = encoder;
		encoder.write(BeginRenderPass(desc));
	}

	public function setPipeline(p:IRenderPipeline):Void {
		encoder.write(SetPipeline(cast p));
	}

	public function setIndexBuffer(b:IIndexBuffer):Void {
		encoder.write(SetIndexBuffer(cast b));
	}

	public function setVertexBuffers(buffers:Array<IVertexBuffer>):Void {
		encoder.write(SetVertexBuffers(cast buffers));
	}

	public function setVertexBuffer(b:IVertexBuffer):Void {
		encoder.write(SetVertexBuffers([cast b]));
	}

	public function draw(start:Int, count:Int):Void {
		encoder.write(Draw(start, count));
	}

	public function drawInstanced(instanceCount:Int, start:Int, count:Int):Void {
		encoder.write(DrawInstanced(instanceCount, start, count));
	}

	public function end() {
		encoder.write(EndRenderPass);
	}

	public function setBindGroup(index:Int, group:IBindGroup) {
		encoder.write(SetBindGroup(index, cast group));
	}
}

private class CommandEncoder implements ICommandEncoder {
	final commands:Array<Command> = [];

	public function new() {}

	public function write(c:Command) {
		commands.push(c);
	}

	public function beginComputePass(desc:ComputePassDescriptor):IComputePass {
		return new ComputePass(this, desc);
	}

	public function beginRenderPass(desc:RenderPassDescriptor):IRenderPass {
		return new RenderPass(this, desc);
	}

	public function finish():ICommandBuffer {
		return new CommandBuffer(commands);
	}
}

private class CommandBuffer implements ICommandBuffer {
	final commands:ReadOnlyArray<Command> = [];

	public function new(commands) {
		this.commands = commands;
	}

	public function execute() {
		for (command in commands) {
			switch command {
				case BeginRenderPass(desc):
					if (desc.colorAttachments[0].texture == KincDriver.dummyTex) {
						assert(desc.colorAttachments.length == 1, "Rendering to swapchain image and extra targets at the same time is not supported right now.");
						Graphics4.restoreRenderTarget();
					} else {
						var targets = new hl.NativeArray<kinc.g4.RenderTarget>(desc.colorAttachments.length);
						for (i => a in desc.colorAttachments) {
							final rt = (cast a.texture : Texture).renderTarget;
							assert(rt != null);
							targets[i] = rt;
						}
						Graphics4.setRenderTargets(targets);
					}
					// var flags = 0;
					// if (col != null)
					// 	flags |= 1;
					// if (depth != null)
					// 	flags |= 2;
					// if (stencil != null)
					// 	flags |= 3;
					// var col:Int = col == null ? 0 : col;
					// var depth:hl.F32 = depth == null ? 0 : (depth : Float);
					// var stencil:hl.F32 = stencil == null ? 0 : (stencil : Float);
					Graphics4.clear(1, 0xFF000000, 0, 0);
				// Graphics4.clear(flags, col, depth, stencil);
				case EndRenderPass:
				case SetVertexBuffers(b):
					var buffers:Array<VertexBuffer> = cast b;
					var vertexBuffers = new hl.NativeArray(buffers.length);
					for (i => buf in buffers)
						vertexBuffers[i] = if (buf.buf != null) buf.buf else return Log.error("Trying to set a disposed vertex buffer.");
					Graphics4.setVertexBuffers(vertexBuffers);
				case SetIndexBuffer(b):
					var b:IndexBuffer = cast b;
					if (b.buf != null)
						Graphics4.setIndexBuffer(b.buf);
					else
						Log.warn("Trying to use disposed index buffer");
				case SetPipeline(p):
					var p:RenderPipeline = cast p;
					if (p.state != null)
						Graphics4.setPipeline(p.state);
					else
						Log.warn("Trying to use disposed pipeline");
				case SetBindGroup(index, b):
				case Draw(start, count):
					if (count < 0)
						Graphics4.drawIndexedVertices();
					else
						Graphics4.drawIndexedVerticesFromTo(start, count);
				case DrawInstanced(instanceCount, start, count):
					if (count < 0)
						Graphics4.drawIndexedVerticesInstanced(instanceCount);
					else
						Graphics4.drawIndexedVerticesInstancedFromTo(instanceCount, start, count);
				case BeginComputePass(desc):
				case SetComputePipeline(p):
				case Compute(x, y, z):
				// kinc.compute.Compute.compute(x, y, z);
				case EndComputePass:
			}
		}
	}
}

class KincDriver implements IGraphicsDriver {
	public final limits:DriverLimits = {};
	public final features:DriverFeatures = {
		compute: false,
		instancedRendering: true,
		flippedRenderTargets: kinc.g4.Graphics4.renderTargetsInvertedY(),
		multipleColorAttachments: true,
		uintIndexBuffers: true
	};

	var window:Int;

	public static final api:kinc.System.GraphicsApi = kinc.System.getGraphicsApi();

	public function new(window:Int) {
		this.window = window;
	}

	public function getName(details = false) {
		return details ? "Kinc on " + api.toString() : "Kinc";
	}

	public function dispose():Void {};

	@:allow(arcane.internal.kinc)
	static final dummyTex = Type.createEmptyInstance(Texture);

	public function begin():ITexture {
		Graphics4.begin(window);
		return dummyTex;
	}

	public function end():Void {
		Graphics4.end(window);
	}

	public function flush():Void {
		Graphics4.flush();
	}

	public function present():Void {
		Graphics4.swapBuffers();
	}

	public function createVertexBuffer(desc:VertexBufferDescriptor):IVertexBuffer {
		return new VertexBuffer(desc);
	}

	public function createIndexBuffer(desc:IndexBufferDescriptor):IIndexBuffer {
		return new IndexBuffer(desc);
	}

	public function createTexture(desc:TextureDescriptor):ITexture {
		return new Texture(desc);
	}

	public function createSampler(desc:SamplerDescriptor):ISampler {
		return cast null;
	}

	public function createShader(desc:ShaderDescriptor):IShaderModule {
		return new Shader(desc);
	}

	public function createComputePipeline(desc:ComputePipelineDescriptor):IComputePipeline {
		return new ComputePipeline(desc);
	}

	public function getCurrentTexture():ITexture {
		return dummyTex;
	}

	public function createUniformBuffer(desc:UniformBufferDescriptor):IUniformBuffer {
		return new UniformBuffer(desc);
	}

	public function createRenderPipeline(desc:RenderPipelineDescriptor):IRenderPipeline {
		return new RenderPipeline(desc);
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

	public function submit(buffers:Array<ICommandBuffer>) {
		for (buf in buffers) {
			(cast buf : CommandBuffer).execute();
		}
	}
}
