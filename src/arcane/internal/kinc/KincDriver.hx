package arcane.internal.kinc;

import arcane.system.IGraphicsDriver;
import kinc.g4.Graphics4;
import kinc.g4.Pipeline.StencilAction;
import kinc.g4.RenderTarget;
import arcane.common.arrays.Float32Array;
import arcane.common.arrays.Int32Array;

class VertexBuffer implements IVertexBuffer {
	public var desc(default, null):VertexBufferDesc;

	public var buf:Null<kinc.g4.VertexBuffer>;
	public var struc:Null<kinc.g4.VertexStructure>;

	public function new(desc:VertexBufferDesc) {
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

	public function upload(start:Int = 0, arr:Array<Float>) {
		assert(buf != null, "Buffer was disposed");
		assert(start + arr.length <= buf.stride() * desc.size, "Trying to upload vertex data outside of buffer bounds!");
		var v = @:nullSafety(Off) buf.lock(start, arr.length);
		for (i in 0...arr.length)
			v[i] = arr[i];
		@:nullSafety(Off) buf.unlock(arr.length);
	}

	private var last_range:Int = 0;

	public function map(start:Int = 0, range:Int = -1):Float32Array {
		assert(buf != null);
		last_range = range == -1 ? desc.size * buf.stride() : range;
		return @:nullSafety(Off) buf.lock(start, last_range);
	}

	public function unmap():Void {
		assert(buf != null);
		buf.unlock(last_range);
	}

	public function dispose() {
		if (buf != null)
			buf.destroy();
		if (struc != null)
			struc.destroy();
		buf = null;
		struc = null;
	}
}

class IndexBuffer implements IIndexBuffer {
	public var desc(default, null):IndexBufferDesc;

	public var buf:Null<kinc.g4.IndexBuffer>;

	public function new(desc:IndexBufferDesc) {
		this.desc = desc;
		// 16 bit buffers are broken in kinc
		this.buf = new kinc.g4.IndexBuffer(desc.size, IbFormat32BIT /*desc.is32 ? IbFormat32BIT : IbFormat16BIT*/);
	}

	public function upload(start:Int = 0, arr:Array<Int>) {
		assert(buf != null, "Buffer disposed");
		assert(start + arr.length <= desc.size, "Trying to upload index data outside of buffer bounds!");
		var x:hl.BytesAccess<Int> = buf.lock();
		for (i in 0...arr.length)
			x[i + start] = arr[i];
		@:nullSafety(Off) buf.unlock();
	}

	public function map(start:Int = 0, range:Int = -1):Int32Array {
		assert(buf != null);
		return (buf.lock() : hl.Bytes).offset(start >> 2);
	}

	public function unmap():Void {
		assert(buf != null);
		buf.unlock();
	}

	public function dispose() {
		if (buf != null) {
			buf.destroy();
			buf = null;
		}
	}
}

@:nullSafety
class Texture implements ITexture {
	public var desc(default, null):TextureDesc;

	public var tex:Null<kinc.g4.Texture>;
	public var renderTarget:Null<kinc.g4.RenderTarget>;

	public function new(desc:TextureDesc) {
		this.desc = desc;

		if (desc.isRenderTarget) {
			renderTarget = RenderTarget.create(desc.width, desc.height, 24, false, Format32Bit, 8, 0);
		} else {
			var tex = new kinc.g4.Texture();
			this.tex = tex;
			tex.init(desc.width, desc.height, FORMAT_RGBA32);
			if (desc.data != null)
				upload(desc.data);
			// tex.generateMipmaps(9);
		}
	}

	public function upload(data:haxe.io.Bytes):Void {
		assert(!desc.isRenderTarget && tex != null);
		var t = tex.lock();
		var stride = @:nullSafety(Off) tex.stride();
		for (y in 0...desc.height) {
			for (x in 0...desc.width) {
				t[y * stride + x * 4 + 0] = data.get((y * desc.width + x) * 4 + 0);
				t[y * stride + x * 4 + 1] = data.get((y * desc.width + x) * 4 + 1);
				t[y * stride + x * 4 + 2] = data.get((y * desc.width + x) * 4 + 2);
				t[y * stride + x * 4 + 3] = data.get((y * desc.width + x) * 4 + 4);
			}
		}
		@:nullSafety(Off) tex.unlock();
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
			case Fragment: FragmentShader;
			case Vertex: VertexShader;
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

class TextureUnit implements ITextureUnit {
	public var tu:kinc.g4.TextureUnit;

	public function new(tu) this.tu = tu;
}

class ConstantLocation implements IConstantLocation {
	public var cl:kinc.g4.ConstantLocation;

	public function new(cl) this.cl = cl;
}

class Pipeline implements IPipeline {
	public var desc(default, null):PipelineDesc;

	public var state:Null<kinc.g4.Pipeline>;

	public function new(desc:PipelineDesc) {
		this.desc = desc;
		var state = new kinc.g4.Pipeline();

		assert(desc.vertexShader.desc.kind.match(Vertex));
		assert(desc.fragmentShader.desc.kind.match(Fragment));

		state.vertex_shader = cast(desc.vertexShader, Shader).shader;
		state.fragment_shader = cast(desc.fragmentShader, Shader).shader;

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

		this.state = state;
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
		return new ConstantLocation(if (state != null) state.getConstantLocation(name) else throw "Pipeline was disposed.");

	public function getTextureUnit(name:String)
		return new TextureUnit(if (state != null) state.getTextureUnit(name) else throw "Pipeline was disposed.");

	public function dispose():Void {
		if (state != null) {
			state.destroy();
			state = null;
		}
	}
}

class KincDriver implements IGraphicsDriver {
	public final renderTargetFlipY:Bool;
	public final instancedRendering = true;
	public final uintIndexBuffers = true;

	var window:Int;

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
		var depth:hl.F32 = depth == null ? 0 : (depth : Float);
		var stencil:hl.F32 = stencil == null ? 0 : (stencil : Float);
		Graphics4.clear(flags, col, depth, stencil);
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

	var renderTargets = new hl.NativeArray(8);

	public function setRenderTarget(?t:ITexture):Void {
		if (t == null) {
			Graphics4.restoreRenderTarget();
			return;
		}
		var rt:Texture = cast t;
		if (rt.desc.isRenderTarget && rt.renderTarget != null) {
			renderTargets[0] = rt.renderTarget;
			Graphics4.setRenderTargets(renderTargets);
		}
	}

	public function setPipeline(p:IPipeline):Void {
		var p:Pipeline = cast p;
		if (p.state != null)
			Graphics4.setPipeline(p.state);
		else
			Log.warn("Trying to use disposed pipeline");
	}

	public function setIndexBuffer(b:IIndexBuffer):Void {
		var b:IndexBuffer = cast b;
		if (b.buf != null)
			Graphics4.setIndexBuffer(b.buf);
		else
			Log.warn("Trying to use disposed index buffer");
	}

	// var vertexBuffers = new hl.NativeArray<kinc.g4.VertexBuffer>(8);

	public function setVertexBuffers(buffers:Array<IVertexBuffer>):Void {
		var buffers:Array<VertexBuffer> = cast buffers;
		var vertexBuffers = new hl.NativeArray(buffers.length);
		for (i => buf in buffers)
			vertexBuffers[i] = if (buf.buf != null) buf.buf else return Log.warn("Trying to set a disposed vertex buffer.");
		Graphics4.setVertexBuffers(vertexBuffers);
	}

	public function setVertexBuffer(b:IVertexBuffer):Void {
		var b:VertexBuffer = cast b;
		if (b.buf != null)
			Graphics4.setVertexBuffer(b.buf);
		else
			Log.warn("Trying to use disposed vertex buffer.");
	}

	public function setTextureUnit(u:ITextureUnit, t:ITexture):Void {
		var tex:Texture = cast t;
		var unit:TextureUnit = cast u;
		@:nullSafety(Off) if (tex.desc.isRenderTarget) {
			tex.renderTarget.useColorAsTexture(unit.tu);
		} else {
			Graphics4.setTexture(unit.tu, tex.tex);
			// Graphics4.setTextureMagnificationFilter(unit.tu, POINT);
			// Graphics4.setTextureMinificationFilter(unit.tu, POINT);
			// Graphics4.setTextureMipmapFilter(unit.tu, POINT);
		}
	}

	public function setConstantLocation(cl:IConstantLocation, floats:Array<Float>):Void {
		Graphics4.setFloats(cast(cl, ConstantLocation).cl, [for (f in floats) (f : Single)]);
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
