package arcane.backend.kinc;

import arcane.Utils.assert;
import kinc.g4.Graphics4;
import arcane.spec.IGraphicsDriver;

class VertexBuffer implements IVertexBuffer {
	public var desc(default, null):VertexBufferDesc;

	public var buf:kinc.g4.VertexBuffer;
	public var struc:kinc.g4.VertexStructure;
	public var stride:Int;

	public function new(desc:VertexBufferDesc) {
		this.desc = desc;
		this.struc = new kinc.g4.VertexStructure();
		this.stride = 0;
		for (el in desc.layout) {
			struc.add(el.name, switch el.kind {
				case Float1: kinc.g4.VertexStructure.VertexData.Float1;
				case Float2: kinc.g4.VertexStructure.VertexData.Float2;
				case Float3: kinc.g4.VertexStructure.VertexData.Float3;
				case Float4: kinc.g4.VertexStructure.VertexData.Float4;
				case Float4x4: kinc.g4.VertexStructure.VertexData.Float4X4;
			});
			stride += switch el.kind {
				case Float1: 1;
				case Float2: 2;
				case Float3: 3;
				case Float4: 4;
				case Float4x4: 0;
			}
		}
		this.buf = new kinc.g4.VertexBuffer(desc.size, struc, DynamicUsage, 0);
	}

	public function upload(start:Int = 0, arr:Array<Float>) {
		#if debug
		assert(start + arr.length <= desc.size * stride, "Trying to upload vertex data outside of buffer bounds!");
		#end
		var v = buf.lock(start, arr.length);
		for (i in 0...arr.length)
			v[i] = arr[i];
		buf.unlock(arr.length);
	}

	public function dispose() {
		buf.destroy();
		struc.destroy();
	}
}

class IndexBuffer implements IIndexBuffer {
	public var desc(default, null):IndexBufferDesc;

	public var buf:kinc.g4.IndexBuffer;

	public function new(desc:IndexBufferDesc) {
		this.desc = desc;
		this.buf = new kinc.g4.IndexBuffer(desc.size, desc.is32 ? IbFormat32BIT : IbFormat16BIT);
	}

	public function upload(start:Int = 0, arr:Array<Int>) {
		var x = buf.lock();
		assert(start + arr.length <= desc.size, "Trying to upload index data outside of buffer bounds!");
		for (i in 0...arr.length)
			x[i + start] = arr[i];
		buf.unlock();
	}

	public function dispose() {
		buf.destroy();
	}
}

class Texture implements ITexture {
	public var desc(default, null):TextureDesc;

	public var tex:kinc.g4.Texture;

	public function new(desc:TextureDesc) {
		tex = new kinc.g4.Texture();

		if(desc.data != null) {
			var img = kinc.Image.fromBytes(desc.data, desc.width, desc.height, FORMAT_RGBA32);
			tex.initFromImage(img);
			img.destroy();
		} else {
			tex.init(desc.width, desc.height, FORMAT_RGBA32);
		}
	}

	public function dispose():Void {
		tex.destroy();
	}
}

class Shader implements IShader {
	public var desc(default, null):ShaderDesc;

	public var shader:kinc.g4.Shader;

	public function new(desc:ShaderDesc) {
		this.desc = desc;
		var bytes = desc.data;
		#if krafix
		if(desc.fromGlslSrc) {
			var len = 0, out = new hl.Bytes(1024 * 1024);
			compileShader(@:privateAccess bytes.toString().toUtf8(), out, len, switch kinc.System.getGraphicsApi() {
				case D3D9: "d3d9";
				case D3D11: "d3d11";
				case D3D12: "d3d11";
				case OpenGL: "essl";
				case Metal: "metal";
				case Vulkan: "vulkan";
			}, switch Sys.systemName().toLowerCase() {
					case "windows": "windows";
					case "linux": "linux";
					case "mac": "mac";
					case _: throw "unsupported system";
				}, switch desc.kind {
					case Vertex: "vert";
					case Fragment: "frag";
				});
			bytes = out.toBytes(len);
		}
		#end
		shader = kinc.g4.Shader.create(bytes, switch desc.kind {
			case Vertex: VertexShader;
			case Fragment: FragmentShader;
		});
	}

	public function dispose():Void {
		shader.destroy();
	}

	#if krafix
	@:hlNative("krafix", "compile_shader")
	static function compileShader(src:hl.Bytes, out:hl.Bytes, outlen:hl.Ref<Int>, targetlang:String, system:String, type:String) {}
	#end
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
				case Float4x4: kinc.g4.VertexStructure.VertexData.Float4X4;
			});
		}

		state.input_layout[0] = struc;
		state.compile();
	}

	public function getConstantLocation(name:String)
		return new CL(state.getConstantLocation(name));

	public function getTextureUnit(name:String)
		return new TU(state.getTextureUnit(name));

	public function dispose():Void {
		state.destroy();
	}
}

@:access(arcane.backend.kinc)
class GraphicsDriver implements IGraphicsDriver {
	public var window:Int;

	public function new(window:Int = 0) this.window = window;

	public function dispose():Void {};

	public function begin():Void Graphics4.begin(window);

	public function clear(?col:arcane.common.Color, ?depth:Float, ?stencil:Int):Void {
		var flags = 0;
		if(col != null)
			flags |= 1;
		if(depth != null)
			flags |= 2;
		if(stencil != null)
			flags |= 3;
		var col:Int = col == null ? 0 : col;
		var depth:hl.F32 = cast depth == null ? 0 : depth;
		var stencil:hl.F32 = cast stencil == null ? 0 : stencil;
		Graphics4.clear(flags, col, depth, stencil);
	}

	public function end():Void Graphics4.end(window);

	public function flush():Void Graphics4.flush();

	public function present():Void {} // Graphics4.swapBuffers is for all windows, so it is handled in System

	public function createVertexBuffer(desc:VertexBufferDesc):IVertexBuffer return new VertexBuffer(desc);

	public function createIndexBuffer(desc:IndexBufferDesc):IIndexBuffer return new IndexBuffer(desc);

	public function createTexture(desc:TextureDesc):ITexture return new Texture(desc);

	public function createShader(desc:ShaderDesc):IShader return new Shader(desc);

	public function createPipeline(desc:PipelineDesc):IPipeline return new Pipeline(desc);

	public function setPipeline(p:IPipeline):Void {
		#if debug
		assert(p != null);
		#end
		Graphics4.setPipeline(cast(p, Pipeline).state);
	}

	public function setIndexBuffer(b:IIndexBuffer):Void {
		#if debug
		assert(b != null);
		#end
		Graphics4.setIndexBuffer(cast(b, IndexBuffer).buf);
	}

	public function setVertexBuffer(b:IVertexBuffer):Void {
		#if debug
		assert(b != null);
		#end
		Graphics4.setVertexBuffer(cast(b, VertexBuffer).buf);
	}

	public function setTextureUnit(u, t) {
		#if debug
		assert(u != null);
		#end
		Graphics4.setTexture(cast(u, TU).tu, cast(t, Texture).tex);
	}

	public function setConstantLocation(cl, floats:Array<hl.F32>) {
		#if debug
		assert(cl != null);
		#end
		Graphics4.setFloats(cast(cl, CL).cl, floats);
	}

	public function draw():Void {
		Graphics4.drawIndexedVertices();
	}
}
