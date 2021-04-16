package arcane.internal;

import arcane.spec.IGraphicsDriver;
import kinc.g4.Graphics4;
import kinc.g4.Pipeline.StencilAction;
import kinc.g4.RenderTarget;

class VertexBuffer implements IVertexBuffer {
	public var desc(default, null):VertexBufferDesc;

	public var buf:kinc.g4.VertexBuffer;
	public var struc:kinc.g4.VertexStructure;

	public function new(desc:VertexBufferDesc) {
		this.desc = desc;
		this.struc = new kinc.g4.VertexStructure();
		for (el in desc.layout) {
			struc.add(el.name, switch el.kind {
				case Float1: Float1;
				case Float2: Float2;
				case Float3: Float3;
				case Float4: Float4;
			});
		}
		this.buf = new kinc.g4.VertexBuffer(desc.size, struc, desc.dyn ? DynamicUsage : StaticUsage, 0);
	}

	public function upload(start:Int = 0, arr:Array<Float>) {
		assert(start + arr.length <= buf.stride(), "Trying to upload vertex data outside of buffer bounds!");
		var v = buf.lockAll();
		for (i in 0...arr.length)
			v[start + i] = arr[i];
		buf.unlockAll();
	}

	public function dispose() {
		buf.destroy();
		struc.destroy();
		buf = null;
		struc = null;
	}
}

class IndexBuffer implements IIndexBuffer {
	public var desc(default, null):IndexBufferDesc;

	public var buf:kinc.g4.IndexBuffer;

	public function new(desc:IndexBufferDesc) {
		this.desc = desc;
		// 16 bit buffers are broken in kinc
		this.buf = new kinc.g4.IndexBuffer(desc.size, IbFormat32BIT /*desc.is32 ? IbFormat32BIT : IbFormat16BIT*/);
	}

	public function upload(start:Int = 0, arr:Array<Int>) {
		assert(start + arr.length <= desc.size, "Trying to upload index data outside of buffer bounds!");
		var x:hl.BytesAccess<Int> = buf.lock();
		for (i in 0...arr.length)
			x[i + start] = arr[i];
		buf.unlock();
	}

	public function dispose() {
		buf.destroy();
		buf = null;
	}
}

class Texture implements ITexture {
	public var desc(default, null):TextureDesc;

	public var tex:kinc.g4.Texture;
	public var renderTarget:kinc.g4.RenderTarget;

	public function new(desc:TextureDesc) {
		this.desc = desc;

		if (desc.isRenderTarget) {
			renderTarget = RenderTarget.create(desc.width, desc.height, 24, false, Format32Bit, 8, 0);
		} else {
			tex = new kinc.g4.Texture();
			tex.init(desc.width, desc.height, FORMAT_RGBA32);
			if (desc.data != null) {
				upload(desc.data);
			}
		}
	}

	public function upload(data:haxe.io.Bytes):Void {
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

	public function dispose():Void {
		if (tex != null)
			tex.destroy();
		if (renderTarget != null)
			renderTarget.destroy();
		tex = null;
		renderTarget = null;
	}
}

class Shader implements IShader {
	public var desc(default, null):ShaderDesc;

	public var shader:kinc.g4.Shader;

	public function new(desc:ShaderDesc) {
		this.desc = desc;
		var bytes = desc.data;
		// #if krafix
		// 	if (desc.fromGlslSrc) {
		// 		var len = 0, out = new hl.Bytes(1024 * 1024);
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
		shader = kinc.g4.Shader.create(bytes, switch desc.kind {
			case Vertex: VertexShader;
			case Fragment: FragmentShader;
		});
	}

	public function dispose():Void {
		shader.destroy();
	}

	// #if krafix
	// @:hlNative("krafix", "compile_shader")
	// static function compileShader(src:hl.Bytes, out:hl.Bytes, outlen:hl.Ref<Int>, targetlang:String, system:String, type:String) {}
	// #end
}

class TU implements ITextureUnit {
	public var tu:kinc.g4.TextureUnit;

	public function new(tu) this.tu = tu;
}

class CL implements IConstantLocation {
	public var cl:kinc.g4.ConstantLocation;

	public function new(cl) this.cl = cl;
}

@:access(arcane.backend.kinc.GraphicsDriver.Shader)
class Pipeline implements IPipeline {
	public var desc(default, null):PipelineDesc;

	public var state:kinc.g4.Pipeline;

	public function new(desc:PipelineDesc) {
		this.desc = desc;
		state = new kinc.g4.Pipeline();

		assert(desc.vertexShader.desc.kind.match(Vertex));
		assert(desc.fragmentShader.desc.kind.match(Fragment));
		
		state.vertex_shader = @:privateAccess cast(desc.vertexShader, Shader).shader;
		state.fragment_shader = @:privateAccess cast(desc.fragmentShader, Shader).shader;

		var struc = new kinc.g4.VertexStructure();
		for (el in desc.inputLayout) {
			struc.add(el.name, switch el.kind {
				case Float1: kinc.g4.VertexStructure.VertexData.Float1;
				case Float2: kinc.g4.VertexStructure.VertexData.Float2;
				case Float3: kinc.g4.VertexStructure.VertexData.Float3;
				case Float4: kinc.g4.VertexStructure.VertexData.Float4;
			});
		}

		state.input_layout[0] = struc;

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

	public function getConstantLocation(name:String)
		return new CL(state.getConstantLocation(name));

	public function getTextureUnit(name:String)
		return new TU(state.getTextureUnit(name));

	public function dispose():Void {
		state.destroy();
		state = null;
	}
}

@:access(arcane.backend.kinc)
class KincDriver implements IGraphicsDriver {
	public final renderTargetFlipY:Bool;

	var window:Int;

	public function supportsFeature(f:GraphicsDriverFeature):Bool
		return switch f {
			case UIntIndexBuffer: true;
			case InstancedRendering: true;
		}

	public function new(window:Int = 0) {
		this.window = window;
		renderTargetFlipY = Graphics4.renderTargetsInvertedY();
	}

	public function dispose():Void {};

	public function begin():Void {
		Graphics4.begin(window);
	}

	public function clear(?col:arcane.common.Color, ?depth:Float, ?stencil:Int):Void {
		var flags = 0;
		if (col != null)
			flags |= 1;
		if (depth != null)
			flags |= 2;
		if (stencil != null)
			flags |= 3;
		var col:Int = col == null ? 0 : col;
		var depth:hl.F32 = cast depth == null ? 0 : depth;
		var stencil:hl.F32 = cast stencil == null ? 0 : stencil;
		Graphics4.clear(flags, col, depth, stencil);
	}

	public function end():Void {
		Graphics4.end(window);
	}

	public function flush():Void {
		Graphics4.flush();
	}

	public function present():Void {}

	public function createVertexBuffer(desc:VertexBufferDesc):IVertexBuffer {
		return new VertexBuffer(desc);
	}

	public function createIndexBuffer(desc:IndexBufferDesc):IIndexBuffer {
		return new IndexBuffer(desc);
	}

	public function createTexture(desc:TextureDesc):ITexture {
		return new Texture(desc);
	}

	public function createShader(desc:ShaderDesc):IShader {
		return new Shader(desc);
	}

	public function createPipeline(desc:PipelineDesc):IPipeline {
		return new Pipeline(desc);
	}

	public function setRenderTarget(?t:ITexture) {
		if (t == null) {
			Graphics4.restoreRenderTarget();
			return;
		}
		var rt:Texture = cast t;

		Graphics4.setRenderTargets([rt.renderTarget]);
	}

	public function setPipeline(p:IPipeline):Void {
		Graphics4.setPipeline(cast(p, Pipeline).state);
	}

	public function setIndexBuffer(b:IIndexBuffer):Void {
		Graphics4.setIndexBuffer(cast(b, IndexBuffer).buf);
	}

	public function setVertexBuffer(b:IVertexBuffer):Void {
		Graphics4.setVertexBuffer(cast(b, VertexBuffer).buf);
	}

	public function setTextureUnit(u:ITextureUnit, t:ITexture) {
		var tex:Texture = cast t;
		var unit:TU = cast u;
		if (tex.desc.isRenderTarget) {
			tex.renderTarget.useColorAsTexture(unit.tu);
		} else {
			Graphics4.setTexture(unit.tu, tex.tex);
		}
	}

	public function setConstantLocation(cl:IConstantLocation, floats:Array<Float>) {
		Graphics4.setFloats(cast(cl, CL).cl, [for (f in floats) (f : Single)]);
	}

	public function draw(start:Int = 0, count:Int = -1):Void {
		if (count < 0)
			Graphics4.drawIndexedVertices();
		else
			Graphics4.drawIndexedVerticesFromTo(start, count);
	}

	public function drawInstanced(instanceCount:Int, start:Int = 0, count:Int = -1):Void {
		if (count < 0)
			Graphics4.drawIndexedVerticesInstanced(instanceCount);
		else
			Graphics4.drawIndexedVerticesInstancedFromTo(instanceCount, start, count);
	}
}
