package backend.html5;

import arcane.spec.IGraphicsDriver;
import js.html.CanvasElement;
import js.html.webgl.GL;
import js.html.webgl.GL2;
import js.html.webgl.Buffer;
import js.html.webgl.Program;
import js.html.webgl.Renderbuffer;
import js.html.webgl.Framebuffer;
import js.html.webgl.UniformLocation;
import js.lib.ArrayBufferView;
import js.lib.Float32Array;
import js.lib.Uint16Array;

private class VertexBuffer implements IVertexBuffer {
	public var desc(default, null):VertexBufferDesc;

	private var buf:Buffer;
	private var driver:WebGLDriver;
	var stride:Int;
	var layout:Array<{
		var name:String;
		var index:Int;
		var size:Int;
		var pos:Int;
	}>;

	public function new(driver:WebGLDriver, desc:VertexBufferDesc) {
		this.driver = driver;
		this.desc = desc;
		this.layout = [];
		this.stride = 0;
		for (idx => i in desc.layout) {
			var size = switch i.kind {
				case Float1: 1;
				case Float2: 2;
				case Float3: 3;
				case Float4: 4;
					// case Float4x4: 0;
			};
			layout.push({
				name: i.name,
				index: idx,
				size: size,
				pos: stride
			});
			stride += size;
		}
		this.buf = driver.gl.createBuffer();
		driver.gl.bindBuffer(GL.ARRAY_BUFFER, buf);
		driver.gl.bufferData(GL.ARRAY_BUFFER, desc.size * stride * 4, desc.dyn ? GL.DYNAMIC_DRAW : GL.STATIC_DRAW);
		driver.gl.bindBuffer(GL.ARRAY_BUFFER, null);
	}

	public function upload(start:Int = 0, arr:Array<Float>):Void {
		var a = new js.lib.Float32Array(arr);
		driver.gl.bindBuffer(GL.ARRAY_BUFFER, buf);
		driver.gl.bufferData(GL.ARRAY_BUFFER, a, desc.dyn ? GL.DYNAMIC_DRAW : GL.STATIC_DRAW);
		driver.gl.bindBuffer(GL.ARRAY_BUFFER, null);
	}

	public function dispose() {
		if(driver.check() && this.buf != null) {
			driver.gl.deleteBuffer(this.buf);
			this.buf = null;
		}
	}
}

private class IndexBuffer implements IIndexBuffer {
	public var desc(default, null):IndexBufferDesc;

	private var buf:Buffer;
	private var driver:WebGLDriver;

	public function new(driver:WebGLDriver, desc:IndexBufferDesc) {
		this.driver = driver;
		this.desc = desc;
		if(desc.is32) {
			untyped alert("WebGL does not support 32 bit index buffers. Have a nice day.");
			throw "See previous alert";
		}
		this.buf = driver.gl.createBuffer();
		this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
		this.driver.gl.bufferData(GL.ELEMENT_ARRAY_BUFFER, desc.size * 2, GL.STATIC_DRAW);
		this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
	}

	public function upload(start:Int = 0, arr:Array<Int>):Void {
		var a = new Uint16Array(arr);
		this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
		this.driver.gl.bufferData(GL.ELEMENT_ARRAY_BUFFER, a, GL.STATIC_DRAW);
		this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
	}

	public function dispose() {
		if(driver.check() && this.buf != null) {
			driver.gl.deleteBuffer(this.buf);
			this.buf = null;
		}
	}
}

private class Shader implements IShader {
	public var desc(default, null):ShaderDesc;

	private var driver:WebGLDriver;
	private var shader:js.html.webgl.Shader;

	public function new(driver:WebGLDriver, desc:ShaderDesc) {
		this.driver = driver;
		this.desc = desc;
		this.shader = driver.gl.createShader(desc.kind.match(Vertex) ? GL.VERTEX_SHADER : GL.FRAGMENT_SHADER);
		driver.gl.shaderSource(shader, desc.data.toString());
		driver.gl.compileShader(shader);
		var log = driver.gl.getShaderInfoLog(shader);
		if((driver.gl.getShaderParameter(shader, GL.COMPILE_STATUS) != cast 1)) {
			throw "Shader compilation error : " + log;
		}
	}

	public function dispose():Void {
		if(!driver.check() || shader == null)
			return;
		driver.gl.deleteShader(shader);
		shader = null;
	}
}

private class ConstantLocation implements IConstantLocation {
	public var type:Int;
	public var name:String;
	public var uniform:UniformLocation;

	public function new(name:String, type:Int, uniform:UniformLocation) {
		this.type = type;
		this.name = name;
		this.uniform = uniform;
	}
}

private class TextureUnit implements ITextureUnit {
	public var index:Int;
	public var name:String;
	public var uniform:UniformLocation;

	public function new(name:String, index:Int, uniform:UniformLocation) {
		this.name = name;
		this.index = index;
		this.uniform = uniform;
	}

	inline function toString() {
		return '#TextureUnit : $name at $index';
	}
}

private class Pipeline implements IPipeline {
	public var desc(default, null):PipelineDesc;

	var driver:WebGLDriver;
	var program:Program;
	var locs:Array<ConstantLocation>;
	var tus:Array<TextureUnit>;

	public function new(driver:WebGLDriver, desc:PipelineDesc) {
		this.driver = driver;
		this.desc = desc;
		this.program = driver.gl.createProgram();
		driver.gl.attachShader(program, @:privateAccess cast(desc.vertexShader, Shader).shader);
		driver.gl.attachShader(program, @:privateAccess cast(desc.fragmentShader, Shader).shader);
		var index = 0;
		for (i in desc.inputLayout) {
			driver.gl.bindAttribLocation(program, index, i.name);
			++index;
		}
		driver.gl.linkProgram(program);

		if(driver.gl.getProgramParameter(program, GL.LINK_STATUS) != 1) {
			throw "WebGL Program Linking failure : " + driver.gl.getProgramInfoLog(program);
		}
		#if debug
		driver.gl.validateProgram(program);

		if(driver.gl.getProgramParameter(program, GL.VALIDATE_STATUS) != 1) {
			throw "WebGL Program Validation failure : " + driver.gl.getProgramInfoLog(program);
		}
		#end
		locs = [];
		tus = [];
		var loc_count:Int = driver.gl.getProgramParameter(program, GL.ACTIVE_UNIFORMS);
		for (i in 0...loc_count) {
			var info = driver.gl.getActiveUniform(program, i);
			var uniform = driver.gl.getUniformLocation(program, info.name);
			if(info.type == GL.SAMPLER_2D || info.type == GL.SAMPLER_CUBE)
				tus.push(new TextureUnit(info.name, tus.length, uniform));
			else
				locs.push(new ConstantLocation(info.name, info.type, uniform));
		}
	}

	public function getConstantLocation(name:String):IConstantLocation {
		if(!driver.check() || program == null)
			return null;
		for (i in locs)
			if(i.name == name || i.name == (name + "[0]"))
				return i;
		trace("Warning : Uniform " + name + " not found.");
		return null;
	}

	public function getTextureUnit(name:String):ITextureUnit {
		if(!driver.check() || program == null)
			return null;
		for (i in tus)
			if(i.name == name)
				return i;
		trace("Warning : Sampler " + name + " not found.");
		return null;
	}

	public function dispose():Void {
		if(!driver.check() || program == null)
			return;
		driver.gl.deleteProgram(program);
		program = null;
	}
}

private class Texture implements ITexture {
	public var desc(default, null):TextureDesc;

	var driver:WebGLDriver;
	var texture:js.html.webgl.Texture;
	var frameBuffer:Framebuffer;
	var renderBuffer:Renderbuffer;

	public function new(driver:WebGLDriver, desc:TextureDesc) {
		this.driver = driver;
		this.desc = desc;
		if(desc.isRenderTarget) {
			texture = driver.gl.createTexture();
			driver.gl.bindTexture(GL.TEXTURE_2D, texture);
			driver.gl.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, desc.width, desc.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
			driver.gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
			driver.gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
			driver.gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
			driver.gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);

			frameBuffer = driver.gl.createFramebuffer();
			driver.gl.bindFramebuffer(GL.FRAMEBUFFER, frameBuffer);
			driver.gl.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, texture, 0);

			renderBuffer = driver.gl.createRenderbuffer();
			driver.gl.bindRenderbuffer(GL.RENDERBUFFER, renderBuffer);
			driver.gl.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_STENCIL, desc.width, desc.height);
			driver.gl.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_STENCIL_ATTACHMENT, GL.RENDERBUFFER, renderBuffer);
			if(driver.gl.checkFramebufferStatus(GL.FRAMEBUFFER) != GL.FRAMEBUFFER_COMPLETE) {
				throw "Failed to create render target";
			}
			driver.gl.bindRenderbuffer(GL.RENDERBUFFER, null);
			driver.gl.bindFramebuffer(GL.FRAMEBUFFER, null);
			driver.gl.bindTexture(GL.TEXTURE_2D, null);
		} else {
			assert(desc.format.match(RGBA), "WebGL only supports rgba textures right now.");
			texture = driver.gl.createTexture();
			driver.gl.bindTexture(GL.TEXTURE_2D, texture);
			driver.gl.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, desc.width, desc.height, 0, GL.RGBA, GL.UNSIGNED_BYTE,
				desc.data == null ? null : @:privateAccess desc.data.b);
			driver.gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
			driver.gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
			driver.gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
			driver.gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
			driver.gl.bindTexture(GL.TEXTURE_2D, null);
		}
	}

	public function dispose() {
		if(driver.check() && texture != null) {
			driver.gl.deleteTexture(texture);
			if(frameBuffer != null) {
				driver.gl.deleteFramebuffer(frameBuffer);
			}
			if(renderBuffer != null) {
				driver.gl.deleteRenderbuffer(renderBuffer);
			}
		}
	}
}

@:allow(backend.html5)
@:access(backend.html5)
class WebGLDriver implements IGraphicsDriver {
	var canvas:CanvasElement;
	var gl:GL;
	var hasGL2:Bool;
	var curVertexBuffer:VertexBuffer;
	var curIndexBuffer:IndexBuffer;
	var curPipeline:Pipeline;

	public function new(gl:GL, canvas:CanvasElement, hasGL2:Bool) {
		this.canvas = canvas;
		this.gl = gl;
		this.hasGL2 = hasGL2;
	}
	public function supportsFeature(f:GraphicsDriverFeature)
		return switch f {
			case ThirtyTwoBitIndexBuffers: false;
			case InstancedRendering: false;
		}
	public function check():Bool return gl != null && !gl.isContextLost();

	public function dispose():Void {
		gl = null;
	}

	public function begin():Void {
		gl.enable(GL.BLEND);
		gl.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
	}

	public function clear(?col:arcane.common.Color, ?depth:Float, ?stencil:Int):Void {
		var bits:arcane.common.IntFlags = 0;
		if(col == null)
			col = 0x000000;
		gl.colorMask(true, true, true, true);
		gl.clearColor(col.r, col.g, col.b, 0xff);
		bits.add(GL.COLOR_BUFFER_BIT);
		if(depth != null) {
			gl.depthMask(true);
			gl.clearDepth(depth);
			bits.add(GL.DEPTH_BUFFER_BIT);
		}
		if(stencil != null) {
			gl.clearStencil(stencil);
			bits.add(GL.STENCIL_BUFFER_BIT);
		}
		gl.clear(bits);
	}

	@:noCompletion var enabled_things:Map<Int, Bool> = new Map();

	private function enable(cap:Int, b:Bool) {
		if(b) {
			if(!enabled_things.exists(cap) || !enabled_things.get(cap)) {
				gl.enable(cap);
				enabled_things.set(cap, true);
			}
		} else {
			if(!enabled_things.exists(cap) || enabled_things.get(cap)) {
				gl.disable(cap);
				enabled_things.set(cap, false);
			}
		}
	}

	public function end():Void {}

	public function flush():Void {}

	public function present():Void {}

	public function createVertexBuffer(desc):IVertexBuffer
		if(!check())
			return null;
		else
			return new VertexBuffer(this, desc);

	public function createIndexBuffer(desc):IIndexBuffer
		if(!check())
			return null;
		else
			return new IndexBuffer(this, desc);

	public function createTexture(desc:TextureDesc):ITexture
		if(!check())
			return null;
		else
			return new Texture(this, desc);

	public function createShader(desc:ShaderDesc):IShader
		if(!check())
			return null;
		else
			return new Shader(this, desc);

	public function createPipeline(desc:PipelineDesc):IPipeline
		if(!check())
			return null;
		else
			return new Pipeline(this, desc);

	private static function convertBlend(b:Blend):Int {
		return switch b {
			case One: GL.ONE;
			case Zero: GL.ZERO;
			case SrcAlpha: GL.SRC_ALPHA;
			case SrcColor: GL.SRC_COLOR;
			case DstAlpha: GL.DST_ALPHA;
			case DstColor: GL.DST_COLOR;
			case OneMinusSrcAlpha: GL.ONE_MINUS_SRC_ALPHA;
			case OneMinusSrcColor: GL.ONE_MINUS_SRC_COLOR;
			case OneMinusDstAlpha: GL.ONE_MINUS_DST_ALPHA;
			case OneMinusDstColor: GL.ONE_MINUS_DST_COLOR;
		}
	}

	private static function convertOperation(o:Operation) {
		return switch o {
			case Add: GL.FUNC_ADD;
			case Sub: GL.FUNC_SUBTRACT;
			case ReverseSub: GL.FUNC_REVERSE_SUBTRACT;
			case Min: 0;
			case Max: 0;
		}
	}

	private static function convertCompare(c:Compare) {
		return switch c {
			case Always: GL.ALWAYS;
			case Never: GL.NEVER;
			case Equal: GL.EQUAL;
			case NotEqual: GL.NOTEQUAL;
			case Greater: GL.GREATER;
			case GreaterEqual: GL.GEQUAL;
			case Less: GL.LESS;
			case LessEqual: GL.LEQUAL;
		}
	}

	private static function convertStencil(c:StencilOp) {
		return switch c {
			case Keep:
				GL.KEEP;
			case Zero:
				GL.ZERO;
			case Replace:
				GL.REPLACE;
			case Increment:
				GL.INCR;
			case IncrementWrap:
				GL.INCR_WRAP;
			case Decrement:
				GL.DECR;
			case DecrementWrap:
				GL.DECR_WRAP;
			case Invert:
				GL.INVERT;
		}
	}

	public function setPipeline(p:IPipeline):Void {
		var state:Pipeline = cast p;
		assert(state.driver == this, "driver mismatch");
		gl.validateProgram(state.program);
		gl.useProgram(state.program);
		curPipeline = state;
		var desc = p.desc;
		if(desc.culling != null) {
			enable(GL.CULL_FACE, true);
			gl.cullFace(switch desc.culling {
				case None: GL.NONE;
				case Back: GL.BACK;
				case Front: GL.FRONT;
				case Both: GL.FRONT_AND_BACK;
			});
		} else {
			enable(GL.CULL_FACE, false);
		}
		if(desc.blend != null) {
			enable(GL.BLEND, true);
			gl.blendFuncSeparate(convertBlend(desc.blend.src), convertBlend(desc.blend.dst), convertBlend(desc.blend.alphaSrc),
				convertBlend(desc.blend.alphaDst));
			gl.blendEquationSeparate(convertOperation(desc.blend.op), convertOperation(desc.blend.alphaOp));
		} else {
			enable(GL.BLEND, false);
		}
		if(desc.stencil != null) {
			enable(GL.STENCIL_TEST, true);
			gl.stencilFuncSeparate(GL.FRONT, convertCompare(desc.stencil.frontTest), desc.stencil.reference, desc.stencil.readMask);
			gl.stencilMaskSeparate(GL.FRONT, desc.stencil.writeMask);
			gl.stencilOpSeparate(GL.FRONT, convertStencil(desc.stencil.frontSTfail), convertStencil(desc.stencil.frontDPfail),
				convertStencil(desc.stencil.frontPass));

			gl.stencilFuncSeparate(GL.BACK, convertCompare(desc.stencil.backTest), desc.stencil.reference, desc.stencil.readMask);
			gl.stencilMaskSeparate(GL.BACK, desc.stencil.writeMask);
			gl.stencilOpSeparate(GL.BACK, convertStencil(desc.stencil.backSTfail), convertStencil(desc.stencil.backDPfail),
				convertStencil(desc.stencil.backPass));
		} else {
			enable(GL.STENCIL_TEST, false);
		}
		if(desc.depthWrite) {
			enable(GL.DEPTH_TEST, true);
			gl.depthMask(true);
			gl.depthFunc(convertCompare(desc.depthTest));
		} else {
			enable(GL.DEPTH_TEST, false);
		}
	}

	public function setRenderTarget(?t:ITexture):Void {
		if(t == null) {
			gl.bindFramebuffer(GL.FRAMEBUFFER, null);
			gl.viewport(0, 0, canvas.width, canvas.height);
		} else {
			var tex:Texture = cast t;
			assert(tex.driver == this, "driver mismatch");
			gl.bindFramebuffer(GL.FRAMEBUFFER, tex.frameBuffer);
			gl.viewport(0, 0, tex.desc.width, tex.desc.height);
		}
	}

	private var enabledVertexAttribs = 0;

	public function setVertexBuffer(b:IVertexBuffer):Void {
		var vb:VertexBuffer = cast b;
		assert(vb.driver == this, "driver mismatch");
		curVertexBuffer = vb;
		for (i in 0...enabledVertexAttribs)
			gl.disableVertexAttribArray(i);
		gl.bindBuffer(GL.ARRAY_BUFFER, curVertexBuffer.buf);
		enabledVertexAttribs = 0;
		for (i in curVertexBuffer.layout) {
			gl.enableVertexAttribArray(i.index);
			gl.vertexAttribPointer(i.index, i.size, GL.FLOAT, false, curVertexBuffer.stride * 4, i.pos * 4);
			++enabledVertexAttribs;
		}
	}

	public function setIndexBuffer(b:IIndexBuffer):Void {
		var ib:IndexBuffer = cast b;
		assert(ib.driver == this, "driver mismatch");
		curIndexBuffer = ib;
	}

	public function setTextureUnit(t:ITextureUnit, tex:ITexture):Void {
		var unit:TextureUnit = cast t;
		var texture:Texture = cast tex;
		gl.activeTexture(GL.TEXTURE0 + unit.index);
		gl.uniform1i(unit.uniform, unit.index);
		gl.bindTexture(GL.TEXTURE_2D, texture.texture);
	}

	public function setConstantLocation(l:IConstantLocation, a:Array<arcane.FastFloat>):Void {
		var loc:ConstantLocation = cast l;
		var l = loc.uniform;
		assert(l != null);
		var a = new Float32Array(a);
		switch loc.type {
			case GL.FLOAT_VEC2:
				gl.uniform2fv(l, a);
			case GL.FLOAT_VEC3:
				gl.uniform3fv(l, a);
			case GL.FLOAT_VEC4:
				gl.uniform4fv(l, a);
			case GL.FLOAT_MAT4:
				gl.uniformMatrix4fv(l, true, a);
			case GL.FLOAT_MAT3:
				gl.uniformMatrix3fv(l, true, a);
			default:
				gl.uniform1fv(l, a);
		}
	}

	public function draw(start:Int = 0,count:Int = -1):Void {
		gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, curIndexBuffer.buf);
		gl.drawElements(GL.TRIANGLES, count == -1 ? curIndexBuffer.desc.size : count, GL.UNSIGNED_SHORT, start);
	}

	public function drawInstanced(instanceCount:Int,start:Int = 0,count:Int = -1):Void {}
}
