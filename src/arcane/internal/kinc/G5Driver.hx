package arcane.internal.kinc;

import kinc.g5.Pipeline.CompareMode;
import kinc.g5.Pipeline.StencilAction;
import kinc.g5.Pipeline.BlendingOperation;
import kinc.g5.Pipeline.BlendingFactor;
import kinc.g5.CommandList;
import kinc.Window;
import kinc.g5.Shader;
import asl.GlslOut;
import kinc.g5.TextureUnit;
import haxe.ds.ReadOnlyArray;
import kinc.compute.ComputeShader;
import arcane.arrays.ArrayBuffer;
import arcane.gpu.IGPUDevice;
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
import kinc.g5.Graphics5;
import kinc.g5.Pipeline as KincPipeline;
import kinc.g5.RenderTarget;
import arcane.arrays.Float32Array;
import arcane.arrays.Int32Array;
import arcane.Utils.assert;
import arcane.util.Log;

private class VertexBuffer implements IVertexBuffer {
	public var desc(default, null):VertexBufferDescriptor;

	public var buf:kinc.g5.VertexBuffer;
	public var struc:kinc.g4.VertexStructure;

	public function new(desc:VertexBufferDescriptor) {
		this.desc = desc;
		var struc = new kinc.g4.VertexStructure();
		for (attribute in desc.attributes) {
			struc.add(attribute.name, switch attribute.kind {
				case Float1: KINC_G4_VERTEX_DATA_F32_1X;
				case Float2: KINC_G4_VERTEX_DATA_F32_2X;
				case Float3: KINC_G4_VERTEX_DATA_F32_3X;
				case Float4: KINC_G4_VERTEX_DATA_F32_4X;
				case Float4x4: KINC_G4_VERTEX_DATA_F32_1X;
			});
		}
		this.buf = new kinc.g5.VertexBuffer(desc.size, struc, true, desc.instanceDataStepRate);
		this.struc = struc;
	}

	public function stride():Int {
		assert(buf != null, "Buffer was disposed");
		return buf.stride();
	}

	public function upload(start:Int, arr:Float32Array) {
		assert(buf != null, "Buffer was disposed");
		assert(start + arr.length <= buf.stride() * desc.size, "Trying to upload vertex data outside of buffer bounds!");
		var v:hl.BytesAccess<hl.F32> = @:nullSafety(Off) buf.lockAll();
		assert(v != null);
		assert(arr != null);
		assert(arr.length > 0);
		// trace(v, arr.length);
		for (i in 0...arr.length)
			v[i + start] = arr[i];
		@:nullSafety(Off) buf.unlockAll();
	}

	private var last_range:Int = -1;

	public function map(start:Int, range:Int):ArrayBuffer {
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

private class IndexBuffer implements IIndexBuffer {
	public var desc(default, null):IndexBufferDescriptor;

	public final buf:kinc.g5.IndexBuffer;

	public function new(desc:IndexBufferDescriptor) {
		this.desc = desc;

		this.buf = new kinc.g5.IndexBuffer(desc.size, desc.is32 ? IBFormat32Bit : IBFormat16Bit, true);
	}

	public function upload(start:Int, arr:Int32Array) {
		assert(buf != null, "Buffer disposed");
		assert(start + arr.length <= desc.size, "Trying to upload index data outside of buffer bounds!");
		var x:hl.BytesAccess<Int> = buf.lock();
		for (i in 0...arr.length)
			x[i + start] = arr[i];
		@:nullSafety(Off) buf.unlock();
	}

	public function map(start:Int, range:Int):ArrayBuffer {
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
private class Texture implements ITexture {
	public var desc(default, null):TextureDescriptor;

	public var tex:Null<kinc.g5.Texture>;
	public var renderTarget:Null<kinc.g5.RenderTarget>;

	public function new(desc:TextureDescriptor) {
		this.desc = desc;

		if (desc.isRenderTarget) {
			renderTarget = RenderTarget.create(desc.width, desc.height, RenderTargetFormat32Bit, 24, 8);
		} else {
			this.tex = kinc.g5.Texture.create(desc.width, desc.height, switch desc.format {
				case RGBA: FORMAT_RGBA32;
				case BGRA: FORMAT_BGRA32;
				case ARGB: throw "assert";
			});
			if (desc.data != null)
				upload(desc.data);
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

private class Sampler implements ISampler {
	public var desc:SamplerDescriptor;

	public function new(desc:SamplerDescriptor) {
		this.desc = desc;
	}
}

private class Shader implements IShaderModule {
	public var desc(default, null):ShaderDescriptor;

	public final shader:Null<kinc.g5.Shader>;
	public final compute:Null<kinc.compute.ComputeShader>;

	public function new(desc:ShaderDescriptor) {
		this.desc = desc;
		final ext = switch desc.module.stage {
			case Vertex: "vert";
			case Fragment: "frag";
			case Compute: "comp";
		}
		var bytes = haxe.Resource.getBytes('${desc.module.id}-$ext-default');
		// trace(bytes.toString());
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
		if (desc.module.stage == Compute) {
			compute = new ComputeShader(bytes);
			shader = null;
		} else {
			compute = null;
			shader = new kinc.g5.Shader(cast bytes.getData().bytes, bytes.length, switch desc.module.stage {
				case Fragment: FRAGMENT;
				case Vertex: VERTEX;
				case _: throw "assert";
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

private class BindGroupLayout implements IBindGroupLayout {
	public final desc:BindGroupLayoutDescriptor;

	public function new(desc:BindGroupLayoutDescriptor) {
		this.desc = desc;
	}
}

private class BindGroup implements IBindGroup {
	public final desc:BindGroupDescriptor;

	public function new(desc:BindGroupDescriptor) {
		this.desc = desc;
	}
}

private class RenderPipeline implements IRenderPipeline {
	public var desc(default, null):RenderPipelineDescriptor;

	public final state:kinc.g5.Pipeline;

	public function new(desc:RenderPipelineDescriptor) {
		this.desc = desc;
		state = new kinc.g5.Pipeline();

		assert(desc.vertexShader.desc.module.stage == Vertex);
		assert(desc.fragmentShader.desc.module.stage == Fragment);

		state.vertex_shader = cast cast(desc.vertexShader, Shader).shader;
		state.fragment_shader = cast cast(desc.fragmentShader, Shader).shader;

		for (idx => el in desc.inputLayout) {
			var struc = new kinc.g4.VertexStructure();
			struc.instanced = el.instanced;
			for (attribute in el.attributes) {
				struc.add(attribute.name, switch attribute.kind {
					case Float1: KINC_G4_VERTEX_DATA_F32_1X;
					case Float2: KINC_G4_VERTEX_DATA_F32_2X;
					case Float3: KINC_G4_VERTEX_DATA_F32_3X;
					case Float4: KINC_G4_VERTEX_DATA_F32_4X;
					case Float4x4: KINC_G4_VERTEX_DATA_F32_1X;
				});
			}
			state.input_layout[idx] = struc;
		}

		state.stencil_reference_value = desc.stencil.reference;
		state.stencil_read_mask = desc.stencil.readMask;
		state.stencil_write_mask = desc.stencil.writeMask;
		state.stencil_front_mode = convertCompare(desc.stencil.frontTest);
		state.stencil_front_fail = convertStencilOp(desc.stencil.frontSTfail);
		state.stencil_front_depth_fail = convertStencilOp(desc.stencil.frontDPfail);
		state.stencil_front_both_pass = convertStencilOp(desc.stencil.frontPass);
		state.stencil_back_mode = convertCompare(desc.stencil.backTest);
		state.stencil_back_fail = convertStencilOp(desc.stencil.backSTfail);
		state.stencil_back_depth_fail = convertStencilOp(desc.stencil.backDPfail);
		state.stencil_back_both_pass = convertStencilOp(desc.stencil.backPass);

		state.cull_mode = switch desc.culling {
			case None: NEVER;
			case Back: COUNTERCLOCKWISE;
			case Front: CLOCKWISE;
			case Both: throw "assert";
		}

		state.depth_write = desc.depthWrite;
		state.depth_mode = convertCompare(desc.depthTest);

		state.blend_source = convertBlend(desc.blend.src);
		state.blend_alpha_source = convertBlend(desc.blend.alphaSrc);
		state.blend_alpha_destination = convertBlend(desc.blend.alphaDst);
		state.blend_destination = convertBlend(desc.blend.dst);
		state.compile();

		this.uniforms = [];
		this.textures = [];
		for (u in (cast desc.vertexShader : Shader).desc.module.uniforms) {
			switch u.t {
				case TMonomorph(r):
				case TVoid, TBool, TInt, TFloat, TVec(_, _), TMat(_, _), TArray(_, _), TStruct(_):
					final location = state.getConstantLocation(u.name);
					final size = asl.Typer.sizeof(u.t);

					uniforms.set(0, [
						{
							// loc: location,
							size: size,
							use_int: u.t == TInt || u.t.match(TVec(TInt, _)) || u.t.match(TMat(TInt, _)) || u.t.match(TArray(TInt, _))
						}]);
				case TSampler2D:
					final unit = state.getTextureUnit(GlslOut.escape(u.name));
					textures.set(0, unit);
				case TSampler2DArray:
				case TSamplerCube:
			}
		}
		for (u in (cast desc.fragmentShader : Shader).desc.module.uniforms) {
			switch u.t {
				case TMonomorph(r):
				case TVoid, TBool, TInt, TFloat, TVec(_, _), TMat(_, _), TArray(_, _), TStruct(_):
					final location = state.getConstantLocation(u.name);
					final size = asl.Typer.sizeof(u.t);

					uniforms.set(0, [
						{
							// loc: location,
							size: size,
							use_int: u.t == TInt || u.t.match(TVec(TInt, _)) || u.t.match(TMat(TInt, _)) || u.t.match(TArray(TInt, _))
						}]);
				case TSampler2D:
					final unit = state.getTextureUnit(GlslOut.escape(u.name));
					textures.set(0, unit);
				case TSampler2DArray:
				case TSamplerCube:
			}
		}
	}

	private static inline function convertBlend(b:Blend):BlendingFactor {
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

	private static inline function convertOperation(o:Operation):BlendingOperation {
		return switch o {
			case Add: ADD;
			case Sub: SUBTRACT;
			case ReverseSub: REVERSE_SUBTRACT;
			case Min: MIN;
			case Max: MAX;
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

	private static inline function convertCompare(c:Compare):CompareMode {
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

	public final uniforms:Map<Int, Array<{
		// var loc:ConstantLocation;
		var size:Int;
		var use_int:Bool;
	}>>;
	public final textures:Map<Int, TextureUnit>;

	public function setBuffer(binding:Int, buffer:UniformBuffer) {
		if (uniforms.exists(binding)) {
			final l:Array<{
				// var loc:ConstantLocation;
				var size:Int;
				var use_int:Bool;
			}> = cast uniforms.get(binding);
			var buf_pos = 0;
			for (s in l) {
				if (buf_pos + s.size > @:privateAccess buffer.data.byteLength)
					throw "Uniform Buffer too small.";
				// if (s.use_int)
				// 	@:privateAccess Graphics5.__setInts(s.loc, buffer.data.b.offset(buf_pos), s.size >> 2);
				// else
				// 	@:privateAccess Graphics5.__setFloats(s.loc, buffer.data.b.offset(buf_pos), s.size >> 2);
				buf_pos += s.size;
			}
		}
	}

	// public static inline function convertAddressing(a:AddressMode):TextureAdressing {
	// 	return switch a {
	// 		case Clamp: CLAMP;
	// 		case Repeat: REPEAT;
	// 		case Mirrored: MIRROR;
	// 	}
	// }
	// public static inline function convertFilter(mode:FilterMode):TextureFilter {
	// 	return switch mode {
	// 		case Nearest: POINT;
	// 		case Linear: LINEAR;
	// 	}
	// }
	// public static inline function convertMipmapFilter(mode:FilterMode):MimapFilter {
	// 	return switch mode {
	// 		case Nearest: POINT;
	// 		case Linear: LINEAR;
	// 	}
	// }

	public function setTexture(binding:Int, texture:Texture, sampler:Sampler) {
		if (textures.exists(binding)) {
			final unit:TextureUnit = cast textures.get(binding);
			if (texture.desc.isRenderTarget) {
				(cast texture.renderTarget).useColorAsTexture(unit);
			} else {
				// Graphics5.setTexture(unit, cast texture.tex);
			}
			// Graphics5.setTextureAddressing(unit, DirectionU, convertAddressing(sampler.desc.uAddressing));
			// Graphics5.setTextureAddressing(unit, DirectionV, convertAddressing(sampler.desc.vAddressing));
			// Graphics5.setTextureAddressing(unit, DirectionW, convertAddressing(sampler.desc.wAddressing));
			// Graphics5.setTextureMagnificationFilter(unit, convertFilter(sampler.desc.magFilter));
			// Graphics5.setTextureMinificationFilter(unit, convertFilter(sampler.desc.minFilter));
			// Graphics5.setTextureMipmapFilter(unit, NONE); // convertMipmapFilter(sampler.desc.minFilter));

			// Graphics5.setTextureCompareMode(unit, sampler.desc.compare != null);

			// todo implement compare func, lod and max anisotropy in kinc
		}
	}

	public function dispose():Void {
		state.destroy();
	}
}

private class ComputePipeline implements IComputePipeline {
	public var desc(default, null):ComputePipelineDescriptor;

	public final shader:ComputeShader;

	// public final uniforms:Map<Int, Array<{
	// 	var loc:ComputeConstantLocation;
	// 	var size:Int;
	// 	var use_int:Bool;
	// }>> = [];
	// public final textures:Map<Int, ComputeTextureUnit> = [];

	public function new(desc:ComputePipelineDescriptor) {
		this.desc = desc;
		this.shader = cast(cast desc.shader : Shader).compute;
	}

	// public function setBuffer(binding:Int, buffer:UniformBuffer) {
	// 	if (uniforms.exists(binding)) {
	// 		final l:Array<{
	// 			var loc:ComputeConstantLocation;
	// 			var size:Int;
	// 			var use_int:Bool;
	// 		}> = cast uniforms.get(binding);
	// 		var buf_pos = 0;
	// 		for (s in l) {
	// 			if (buf_pos + s.size > @:privateAccess buffer.data.byteLength)
	// 				throw "Uniform Buffer too small.";
	// 			@:privateAccess kinc.compute.Compute.__setFloats(s.loc, buffer.data.b.offset(buf_pos), s.size >> 2);
	// 			buf_pos += s.size;
	// 		}
	// 	}
	// }
	// public function setTexture(binding:Int, texture:Texture, sampler:Sampler) {
	// 	if (textures.exists(binding)) {
	// 		final unit:ComputeTextureUnit = cast textures.get(binding);
	// 		if (texture.desc.isRenderTarget) {
	// 			kinc.compute.Compute.setRenderTarget(unit, cast texture.renderTarget, READ_WRITE);
	// 		} else {
	// 			kinc.compute.Compute.setTexture(unit, cast texture.tex, READ_WRITE);
	// 		}
	// 		kinc.compute.Compute.setTextureAddressing(unit, DirectionU, RenderPipeline.convertAddressing(sampler.desc.uAddressing));
	// 		kinc.compute.Compute.setTextureAddressing(unit, DirectionV, RenderPipeline.convertAddressing(sampler.desc.vAddressing));
	// 		kinc.compute.Compute.setTextureAddressing(unit, DirectionW, RenderPipeline.convertAddressing(sampler.desc.wAddressing));
	// 		kinc.compute.Compute.setTextureMagnificationFilter(unit, RenderPipeline.convertFilter(sampler.desc.magFilter));
	// 		kinc.compute.Compute.setTextureMinificationFilter(unit, RenderPipeline.convertFilter(sampler.desc.minFilter));
	// 		kinc.compute.Compute.setTextureMipmapFilter(unit, RenderPipeline.convertMipmapFilter(sampler.desc.minFilter));
	// 	}
	// }

	public function dispose() {}
}

private class ComputePass implements IComputePass {
	final encoder:CommandEncoder;

	public function new(encoder:CommandEncoder, desc:ComputePassDescriptor) {
		this.encoder = encoder;
	}

	public function setPipeline(p:IComputePipeline) {
		throw "TODO";
	}

	public function dispatch(x:Int, y:Int, z:Int) {
		throw "TODO";
	}

	public function setBindGroup(index:Int, group:IBindGroup) {
		throw "TODO";
	}

	public function end() {
		throw "TODO";
	}
}

private class RenderPass implements IRenderPass {
	final encoder:CommandEncoder;
	final targets:hl.NativeArray<RenderTarget>;

	var curPipeline:Null<RenderPipeline> = null;
	var bindGroups:Map<Int, BindGroup> = [];
	var groupsChanged:Bool = false;

	public function new(encoder:CommandEncoder, desc:RenderPassDescriptor) {
		this.encoder = encoder;

		targets = new hl.NativeArray(desc.colorAttachments.length);
		for (i => attachment in desc.colorAttachments) {
			var t:RenderTarget = cast(cast attachment.texture : Texture).renderTarget;
			encoder.list.framebufferToRenderTargetBarrier(t);
			targets[i] = t;
		}
		encoder.list.setRenderTargets(targets);
		for (i => attachment in desc.colorAttachments) {
			var target = cast(cast desc.colorAttachments[i].texture : Texture).renderTarget;
			switch attachment.load {
				case Clear(color):
					encoder.list.clear(target, Color, color == null ? 0 : color, 0, 0);
				case Load:
					encoder.list.clear(target, Color, 0, 0, 0);
			}
		}
		// TODO: depth textures, somehow
	}

	public function setPipeline(p:IRenderPipeline):Void {
		encoder.list.setPipeline((cast p : RenderPipeline).state);
	}

	public function setIndexBuffer(b:IIndexBuffer):Void {
		encoder.list.setIndexBuffer((cast b : IndexBuffer).buf);
	}

	public function setVertexBuffers(buffers:Array<IVertexBuffer>):Void {
		var arr = new hl.NativeArray(buffers.length);
		for (i => buf in buffers) {
			arr[i] = (cast buf : VertexBuffer).buf;
		}
		var offsets:hl.BytesAccess<Int> = new hl.Bytes(buffers.length * 4);
		for (i in 0...buffers.length) {
			offsets[i] = 0;
		}
		encoder.list.setVertexBuffers(arr, offsets);
	}

	public function setVertexBuffer(b:IVertexBuffer):Void {
		setVertexBuffers([b]);
	}

	public function draw(start:Int, count:Int):Void {
		if(groupsChanged) {
			for(group in bindGroups) {
				for(entry in group.desc.entries) {
					@:nullSafety(Off) switch entry.resource {
						case Buffer(buffer):
						case Texture(texture, sampler):
							assert(curPipeline != null);
							var unit = curPipeline.state.getTextureUnit("tex");
							// encoder.list.set
					}
				}
			}
		}
		encoder.list.drawIndexedVerticesFromTo(start, count);
	}

	public function drawInstanced(instanceCount:Int, start:Int, count:Int):Void {
		encoder.list.drawIndexedVerticesInstancedFromTo(instanceCount, start, count);
	}

	public function end() {
		for(target in targets) {
			encoder.list.renderTargetToFramebufferBarrier(target);
		}
	}

	public function setBindGroup(index:Int, group:IBindGroup) {
		bindGroups[index] = cast group;
	}
}

private class CommandEncoder implements ICommandEncoder {
	public final list:CommandList;

	public function new() {
		list = new CommandList();
		list.begin();
	}

	public function beginComputePass(desc:ComputePassDescriptor):IComputePass {
		return new ComputePass(this, desc);
	}

	public function beginRenderPass(desc:RenderPassDescriptor):IRenderPass {
		return new RenderPass(this, desc);
	}

	public function finish():ICommandBuffer {
		list.end();
		return new CommandBuffer(list);
	}
}

private class CommandBuffer implements ICommandBuffer {
	final list:CommandList;

	public function new(list:CommandList) {
		this.list = list;
	}

	public function execute() {
		list.execute();
		list.waitForExecutionToFinish();
	}
}

class G5Driver implements IGPUDevice {
	public final limits:DriverLimits = {};
	public final features:DriverFeatures = {
		compute: false,
		instancedRendering: true,
		flippedRenderTargets: Graphics5.renderTargetsInvertedY(),
		multipleColorAttachments: true,
		uintIndexBuffers: true
	};

	var window:Int;

	public static final api:kinc.System.GraphicsApi = kinc.System.getGraphicsApi();

	var renderTargets:Array<Texture>;
	var currentRenderTarget:Int;

	public function new(window:Int) {
		this.window = window;

		renderTargets = [
			for (_ in 0...2) {
				final target:Texture = untyped $new(Texture);
				@:privateAccess target.desc = {
					width: Window.width(window),
					height: Window.height(window),
					format: RGBA,
					isRenderTarget: true
				};
				target.renderTarget = RenderTarget.createFramebuffer(Window.width(window), Window.height(window), RenderTargetFormat32Bit, 24, 16);
				target;
			}
			// RenderTarget.create(Window.width(window), Window.height(window), 24, false, RenderTargetFormat32Bit, 16, -1),
			// RenderTarget.create(Window.width(window), Window.height(window), 24, false, RenderTargetFormat32Bit, 16, -2)
		];
		currentRenderTarget = 0;
	}

	public function getName(details = false) {
		return details ? "Kinc on " + api.toString() : "Kinc";
	}

	public function dispose():Void {};

	public function flush():Void {
		Graphics5.flush();
	}

	public function present():Void {
		Graphics5.swapBuffers();
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
		return new Sampler(desc);
	}

	public function createShader(desc:ShaderDescriptor):IShaderModule {
		return new Shader(desc);
	}

	public function createComputePipeline(desc:ComputePipelineDescriptor):IComputePipeline {
		return new ComputePipeline(desc);
	}

	public function getCurrentTexture():ITexture {
		var rt = renderTargets[currentRenderTarget++ %= renderTargets.length];
		Graphics5.begin(cast rt.renderTarget, window);
		return rt;
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
		Graphics5.end(window);
	}
}
