package arcane.internal;

import js.html.webgl.extension.ANGLEInstancedArrays;
import arcane.system.IGraphicsDriver;
import js.html.CanvasElement;
import js.html.webgl.Buffer;
import js.html.webgl.Framebuffer;
import js.html.webgl.GL2;
import js.html.webgl.GL;
import js.html.webgl.Program;
import js.html.webgl.Renderbuffer;
import js.html.webgl.UniformLocation;
import js.lib.Float32Array;
import js.lib.Uint16Array;
import js.lib.Uint32Array;

@:access(WebGLDriver)
private class Base<T> {
	public var desc(default, null):T;

	private var driver:WebGLDriver;

	public function new(driver:WebGLDriver, desc:T) {
		this.desc = desc;
		this.driver = driver;
		init();
	}

	function init():Void {};

	public function check(?driver:WebGLDriver):Bool {
		if (driver != null) {
			assert(driver == this.driver, "driver mismatch");
		}
		return this.driver.check();
	}
}

class VertexBuffer extends Base<VertexBufferDesc> implements IVertexBuffer {
	private var buf:Buffer;
	var stride:Int;
	var layout:Array<{
		var name:String;
		var index:Int;
		var size:Int;
		var pos:Int;
	}>;

	override function init() {
		this.layout = [];
		this.stride = 0;
		for (idx => i in desc.layout) {
			var size = switch i.kind {
				case Float1: 1;
				case Float2: 2;
				case Float3: 3;
				case Float4: 4;
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
		driver.gl.bufferSubData(GL.ARRAY_BUFFER, start * 4, a);
		driver.gl.bindBuffer(GL.ARRAY_BUFFER, null);
	}

	public function dispose() {
		if (driver.check() && this.buf != null) {
			driver.gl.deleteBuffer(this.buf);
			this.buf = null;
		}
	}
}

class IndexBuffer extends Base<IndexBufferDesc> implements IIndexBuffer {
	private var buf:Buffer;

	override function init() {
		if (desc.is32 && !this.driver.uintIndexBuffers) {
			throw "32bit buffers are not supported without webgl2 or the OES_element_index_uint extension.";
		}
		this.buf = driver.gl.createBuffer();
		this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
		this.driver.gl.bufferData(GL.ELEMENT_ARRAY_BUFFER, desc.size * (desc.is32 ? 4 : 2), GL.STATIC_DRAW);
		this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
	}

	public function upload(start:Int = 0, arr:Array<Int>):Void {
		if (desc.is32) {
			var a = new Uint32Array(arr);
			this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
			this.driver.gl.bufferSubData(GL.ELEMENT_ARRAY_BUFFER, start << 2, a);
			this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
		} else {
			var a = new Uint16Array(arr);
			this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
			this.driver.gl.bufferSubData(GL.ELEMENT_ARRAY_BUFFER, start << 1, a);
			this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
		}
	}

	public function dispose() {
		if (driver.check() && this.buf != null) {
			driver.gl.deleteBuffer(this.buf);
			this.buf = null;
		}
	}
}

class Shader extends Base<ShaderDesc> implements IShader {
	private var shader:js.html.webgl.Shader;

	override function init() {
		assert(desc.data != null);

		this.shader = driver.gl.createShader(desc.kind.match(Vertex) ? GL.VERTEX_SHADER : GL.FRAGMENT_SHADER);
		driver.gl.shaderSource(shader, desc.data.toString());
		driver.gl.compileShader(shader);
		var log = driver.gl.getShaderInfoLog(shader);
		if ((driver.gl.getShaderParameter(shader, GL.COMPILE_STATUS) != cast 1)) {
			throw "Shader compilation error : " + log;
		}
	}

	public function dispose():Void {
		if (!driver.check() || shader == null)
			return;
		driver.gl.deleteShader(shader);
		shader = null;
	}
}

class ConstantLocation implements IConstantLocation {
	public var type:Int;
	public var name:String;
	public var uniform:UniformLocation;

	public function new(name:String, type:Int, uniform:UniformLocation) {
		this.type = type;
		this.name = name;
		this.uniform = uniform;
	}

	function toString() {
		return '#ConstantLocation : $name with $type at uniform $uniform';
	}
}

class TextureUnit implements ITextureUnit {
	public var index:Int;
	public var name:String;
	public var uniform:UniformLocation;

	public function new(name:String, index:Int, uniform:UniformLocation) {
		this.name = name;
		this.index = index;
		this.uniform = uniform;
	}

	function toString() {
		return '#TextureUnit : $name at $index';
	}
}

class Pipeline extends Base<PipelineDesc> implements IPipeline {
	var program:Program;
	var locs:Array<ConstantLocation>;
	var tus:Array<TextureUnit>;

	override function init() {
		this.program = driver.gl.createProgram();
		driver.gl.attachShader(program, @:privateAccess cast(desc.vertexShader, Shader).shader);
		driver.gl.attachShader(program, @:privateAccess cast(desc.fragmentShader, Shader).shader);
		var index = 0;
		for (i in desc.inputLayout) {
			driver.gl.bindAttribLocation(program, index, i.name);
			++index;
		}
		driver.gl.linkProgram(program);

		if (driver.gl.getProgramParameter(program, GL.LINK_STATUS) != 1) {
			throw "WebGL Program Linking failure : " + driver.gl.getProgramInfoLog(program);
		}
		#if debug
		driver.gl.validateProgram(program);
		if (driver.gl.getProgramParameter(program, GL.VALIDATE_STATUS) != 1) {
			throw "WebGL Program Validation failure : " + driver.gl.getProgramInfoLog(program);
		}
		#end
		locs = [];
		tus = [];
		var loc_count:Int = driver.gl.getProgramParameter(program, GL.ACTIVE_UNIFORMS);
		for (i in 0...loc_count) {
			var info = driver.gl.getActiveUniform(program, i);
			var uniform = driver.gl.getUniformLocation(program, info.name);
			if (info.type == GL.SAMPLER_2D || info.type == GL.SAMPLER_CUBE)
				tus.push(new TextureUnit(info.name, tus.length, uniform));
			else
				locs.push(new ConstantLocation(info.name, info.type, uniform));
		}
	}

	public function getConstantLocation(name:String):IConstantLocation {
		if (!driver.check() || program == null)
			return null;
		for (i in locs)
			if (i.name == name || i.name == (name + "[0]"))
				return i;
		Log.warn("Uniform " + name + " not found.");
		return new ConstantLocation("invalid", -1, null);
	}

	public function getTextureUnit(name:String):ITextureUnit {
		if (!driver.check() || program == null)
			return null;
		for (i in tus)
			if (i.name == name)
				return i;
		Log.warn("Sampler " + name + " not found.");
		return new TextureUnit("invalid", -1, null);
	}

	public function dispose():Void {
		if (!driver.check() || program == null)
			return;
		driver.gl.deleteProgram(program);
		program = null;
	}
}

class Texture extends Base<TextureDesc> implements ITexture {
	var texture:js.html.webgl.Texture;
	var frameBuffer:Framebuffer;
	var renderBuffer:Renderbuffer;

	override function init() {
		if (desc.isRenderTarget) {
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

			if (driver.gl.checkFramebufferStatus(GL.FRAMEBUFFER) != GL.FRAMEBUFFER_COMPLETE) {
				throw "Failed to create framebuffer.";
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

	public function upload(data:haxe.io.Bytes) {
		if (!desc.isRenderTarget) {
			driver.gl.bindTexture(GL.TEXTURE_2D, texture);
			driver.gl.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, desc.width, desc.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, @:privateAccess data.b);
			driver.gl.bindTexture(GL.TEXTURE_2D, null);
		}
	}

	public function dispose() {
		if (driver.check() && texture != null) {
			driver.gl.deleteTexture(texture);
			texture = null;
			if (frameBuffer != null) {
				driver.gl.deleteFramebuffer(frameBuffer);
				frameBuffer = null;
			}
			if (renderBuffer != null) {
				driver.gl.deleteRenderbuffer(renderBuffer);
				renderBuffer = null;
			}
		}
	}
}

@:allow(arcane.internal)
@:access(arcane.internal)
class WebGLDriver implements IGraphicsDriver {
	public final renderTargetFlipY:Bool = true;
	public final instancedRendering:Bool;
	public final uintIndexBuffers:Bool;

	var canvas:CanvasElement;
	var gl:GL;

	var gl2(get, never):GL2;
	var hasGL2:Bool;

	var curVertexBuffer:VertexBuffer;
	var curIndexBuffer:IndexBuffer;
	var curPipeline:Pipeline;

	inline function get_gl2():GL2 return cast gl;

	public function new(gl:GL, canvas:CanvasElement, hasGL2:Bool) {
		this.canvas = canvas;
		this.gl = gl;
		this.hasGL2 = hasGL2;

		if (hasGL2) {
			this.instancedRendering = true;
			this.uintIndexBuffers = true;
		} else {
			this.uintIndexBuffers = gl.getExtension(OES_element_index_uint) != null;
			var ext = gl.getExtension(ANGLE_instanced_arrays);
			if (ext != null) {
				this.instancedRendering = true;
				Reflect.setField(gl, "drawElementsInstanced", ext.drawElementsInstancedANGLE);
				Reflect.setField(gl, "drawArraysInstanced", ext.drawArraysInstancedANGLE);
				Reflect.setField(gl, "vertexAtribDivisor", ext.vertexAttribDivisorANGLE);
			} else {
				this.instancedRendering = false;
			}
		}
	}

	public function check():Bool {
		return gl != null && !gl.isContextLost();
	}

	public function dispose():Void {
		gl = null;
	}

	public function begin():Void {
		gl.enable(GL.BLEND);
		gl.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
	}

	public function clear(?col:arcane.common.Color, ?depth:Float, ?stencil:Int):Void {
		var bits:arcane.common.IntFlags = 0;
		if (col == null)
			col = 0x000000;
		gl.colorMask(true, true, true, true);
		gl.clearColor(col.r, col.g, col.b, 0xff);
		bits.add(GL.COLOR_BUFFER_BIT);
		if (depth != null) {
			gl.depthMask(true);
			gl.clearDepth(depth);
			bits.add(GL.DEPTH_BUFFER_BIT);
		}
		if (stencil != null) {
			gl.clearStencil(stencil);
			bits.add(GL.STENCIL_BUFFER_BIT);
		}
		gl.clear(bits);
	}

	@:noCompletion var enabled_things:Map<Int, Bool> = new Map();

	function enable(cap:Int, b:Bool) {
		if (b) {
			if (!enabled_things.exists(cap) || !enabled_things.get(cap)) {
				gl.enable(cap);
				enabled_things.set(cap, true);
			}
		} else {
			if (!enabled_things.exists(cap) || enabled_things.get(cap)) {
				gl.disable(cap);
				enabled_things.set(cap, false);
			}
		}
	}

	public function end():Void {}

	public function flush():Void {}

	public function present():Void {}

	public function createVertexBuffer(desc):IVertexBuffer
		if (!check())
			return null;
		else
			return new VertexBuffer(this, desc);

	public function createIndexBuffer(desc):IIndexBuffer
		if (!check())
			return null;
		else
			return new IndexBuffer(this, desc);

	public function createTexture(desc:TextureDesc):ITexture
		if (!check())
			return null;
		else
			return new Texture(this, desc);

	public function createShader(desc:ShaderDesc):IShader
		if (!check())
			return null;
		else
			return new Shader(this, desc);

	public function createPipeline(desc:PipelineDesc):IPipeline
		if (!check())
			return null;
		else
			return new Pipeline(this, desc);

	static function convertBlend(b:Blend):Int {
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

	static function convertOperation(o:Operation) {
		return switch o {
			case Add: GL.FUNC_ADD;
			case Sub: GL.FUNC_SUBTRACT;
			case ReverseSub: GL.FUNC_REVERSE_SUBTRACT;
			case Min: 0;
			case Max: 0;
		}
	}

	static function convertCompare(c:Compare) {
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

	static function convertStencil(c:StencilOp) {
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
		gl.useProgram(state.program);
		curPipeline = state;
		var desc = p.desc;
		switch desc.culling {
			case None, null:
				enable(GL.CULL_FACE, false);
			case Back:
				enable(GL.CULL_FACE, true);
				gl.cullFace(GL.BACK);
			case Front:
				enable(GL.CULL_FACE, true);
				gl.cullFace(GL.FRONT);
			case Both:
				enable(GL.CULL_FACE, true);
				gl.cullFace(GL.FRONT_AND_BACK);
		};
		if (desc.blend != null) {
			enable(GL.BLEND, true);
			gl.blendFuncSeparate(convertBlend(desc.blend.src), convertBlend(desc.blend.dst), convertBlend(desc.blend.alphaSrc),
				convertBlend(desc.blend.alphaDst));
			gl.blendEquationSeparate(convertOperation(desc.blend.op), convertOperation(desc.blend.alphaOp));
		} else {
			enable(GL.BLEND, false);
		}
		if (desc.stencil != null) {
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
		if (desc.depthWrite) {
			enable(GL.DEPTH_TEST, true);
			gl.depthMask(true);
			gl.depthFunc(convertCompare(desc.depthTest));
		} else {
			enable(GL.DEPTH_TEST, false);
		}
	}

	public function setRenderTarget(?t:ITexture):Void {
		if (t == null) {
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
			if(instancedRendering) {
				gl2.vertexAttribDivisor(i.index,0);
			}
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
		if (unit.index == -1) {
			return;
		}
		gl.uniform1i(unit.uniform, unit.index);
		gl.activeTexture(GL.TEXTURE0 + unit.index);
		gl.bindTexture(GL.TEXTURE_2D, texture.texture);
	}

	public function setConstantLocation(l:IConstantLocation, a:Array<Float>):Void {
		var loc:ConstantLocation = cast l;
		var l = loc.uniform;
		if (loc.type == -1) {
			return;
		}
		var a = new Float32Array(a);
		switch loc.type {
			case GL.FLOAT_VEC2:
				gl.uniform2fv(l, a);
			case GL.FLOAT_VEC3:
				gl.uniform3fv(l, a);
			case GL.FLOAT_VEC4:
				gl.uniform4fv(l, a);
			case GL.FLOAT_MAT4:
				gl.uniformMatrix4fv(l, false, a);
			case GL.FLOAT_MAT3:
				gl.uniformMatrix3fv(l, false, a);
			default:
				gl.uniform1fv(l, a);
		}
	}

	public function draw(start:Int = 0, count:Int = -1):Void {
		gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, curIndexBuffer.buf);
		gl.drawElements(GL.TRIANGLES, count == -1 ? curIndexBuffer.desc.size : count, curIndexBuffer.desc.is32 ? GL.UNSIGNED_INT : GL.UNSIGNED_SHORT, start);
	}

	public function drawInstanced(instanceCount:Int, start:Int = 0, count:Int = -1):Void {
		if(instancedRendering) {
			gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER,curIndexBuffer.buf);
			gl2.drawElementsInstanced(GL.TRIANGLES, count == -1 ? curIndexBuffer.desc.size : count, curIndexBuffer.desc.is32 ? GL.UNSIGNED_INT : GL.UNSIGNED_SHORT, start,instanceCount);
		}
	}
}
