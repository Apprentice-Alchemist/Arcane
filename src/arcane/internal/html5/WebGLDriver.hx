package arcane.internal.html5;

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
import js.lib.Int32Array;

class VertexBuffer implements IVertexBuffer {
	public var desc:VertexBufferDesc;

	var driver:WebGLDriver;
	var buf:Buffer;
	var stride:Int;
	var layout:Array<{
		var name:String;
		var index:Int;
		var size:Int;
		var pos:Int;
	}>;
	var data:Float32Array;

	public function new(driver, desc) {
		this.driver = driver;
		this.desc = desc;

		this.layout = [];
		this.stride = 0;
		for (idx => att in desc.attributes) {
			var size = switch att.kind {
				case Float1: 1;
				case Float2: 2;
				case Float3: 3;
				case Float4: 4;
				case Float4x4: 16;
			}
			layout.push({
				name: att.name,
				index: idx,
				size: size,
				pos: stride
			});
			stride += size;
		}

		this.data = new js.lib.Float32Array(desc.size * stride);
		this.buf = driver.gl.createBuffer();
		driver.gl.bindBuffer(GL.ARRAY_BUFFER, buf);
		driver.gl.bufferData(GL.ARRAY_BUFFER, desc.size * stride * 4, desc.dyn ? GL.DYNAMIC_DRAW : GL.STATIC_DRAW);
		@:nullSafety(Off) driver.gl.bindBuffer(GL.ARRAY_BUFFER, null);
	}

	public function upload(start:Int = 0, arr:Array<Float>):Void {
		var a = new js.lib.Float32Array(arr);
		driver.gl.bindBuffer(GL.ARRAY_BUFFER, buf);
		driver.gl.bufferSubData(GL.ARRAY_BUFFER, start * 4, a);
		@:nullSafety(Off) driver.gl.bindBuffer(GL.ARRAY_BUFFER, null);
	}

	var last_start = 0;
	var last_end = 0;

	public function map(start:Int = 0, range:Int = -1):arcane.common.arrays.Float32Array {
		last_start = start;
		last_end = range == -1 ? data.length : start + range;
		return data.subarray(last_start, last_end);
	}

	public function unmap():Void {
		driver.gl.bindBuffer(GL.ARRAY_BUFFER, buf);
		driver.gl.bufferSubData(GL.ARRAY_BUFFER, last_start * 4, data.subarray(last_start, last_end));
		@:nullSafety(Off) driver.gl.bindBuffer(GL.ARRAY_BUFFER, null);
	}

	public function dispose() {
		if (driver.check()) {
			driver.gl.deleteBuffer(this.buf);
		}
	}

	public inline function check(?driver:WebGLDriver):Bool {
		if (driver != null) {
			assert(driver == this.driver, "driver mismatch");
		}
		return this.driver.check();
	}
}

class IndexBuffer implements IIndexBuffer {
	public var desc:IndexBufferDesc;

	var driver:WebGLDriver;
	var buf:Buffer;
	var data:Int32Array;

	public function new(driver, desc) {
		this.driver = driver;
		this.desc = desc;

		if (desc.is32 && !this.driver.uintIndexBuffers) {
			throw "32bit buffers are not supported without webgl2 or the OES_element_index_uint extension.";
		}
		this.data = new Int32Array(desc.size);
		this.buf = driver.gl.createBuffer();
		this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
		this.driver.gl.bufferData(GL.ELEMENT_ARRAY_BUFFER, desc.size * (desc.is32 ? 4 : 2), GL.STATIC_DRAW);
		@:nullSafety(Off) this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
	}

	public function upload(start:Int = 0, arr:Array<Int>):Void {
		if (desc.is32) {
			var a = new Uint32Array(arr);
			this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
			this.driver.gl.bufferSubData(GL.ELEMENT_ARRAY_BUFFER, start * 4, a);
			@:nullSafety(Off) this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
		} else {
			var a = new Uint16Array(arr);
			this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
			this.driver.gl.bufferSubData(GL.ELEMENT_ARRAY_BUFFER, start * 2, a);
			@:nullSafety(Off) this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
		}
	}

	var last_start = 0;
	var last_end = 0;

	public function map(start:Int = 0, range:Int = -1):arcane.common.arrays.Int32Array {
		last_start = start;
		last_end = range == -1 ? data.length : start + range;
		return data.subarray(last_start, last_end);
	}

	public function unmap():Void {
		if (desc.is32) {
			var a = data.subarray(last_start, last_end);
			this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
			this.driver.gl.bufferSubData(GL.ELEMENT_ARRAY_BUFFER, last_start * 4, a);
			@:nullSafety(Off) this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
		} else {
			var a = new Uint16Array(data.subarray(last_start, last_end));
			this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
			this.driver.gl.bufferSubData(GL.ELEMENT_ARRAY_BUFFER, last_start * 2, a);
			@:nullSafety(Off) this.driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
		}
	}

	public function dispose() {
		if (driver.check()) {
			driver.gl.deleteBuffer(this.buf);
		}
	}

	public inline function check(?driver:WebGLDriver):Bool {
		if (driver != null) {
			assert(driver == this.driver, "driver mismatch");
		}
		return this.driver.check();
	}
}

class Shader implements IShader {
	public var desc:ShaderDesc;

	var driver:WebGLDriver;
	var shader:js.html.webgl.Shader;

	public function new(driver, desc) {
		this.driver = driver;
		this.desc = desc;

		this.shader = driver.gl.createShader(desc.kind.match(Vertex) ? GL.VERTEX_SHADER : GL.FRAGMENT_SHADER);
		driver.gl.shaderSource(shader, desc.data.toString());
		driver.gl.compileShader(shader);
		var log = driver.gl.getShaderInfoLog(shader);
		if ((driver.gl.getShaderParameter(shader, GL.COMPILE_STATUS) != cast 1)) {
			(untyped alert)(log + "\n" + desc.data);
			throw "";
			// throw "Shader compilation error : " + log;
		}
	}

	public function dispose():Void {
		if (!driver.check())
			return;
		driver.gl.deleteShader(shader);
	}

	public inline function check(?driver:WebGLDriver):Bool {
		if (driver != null) {
			assert(driver == this.driver, "driver mismatch");
		}
		return this.driver.check();
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

class Pipeline implements IPipeline {
	public var desc:PipelineDesc;

	var driver:WebGLDriver;
	var program:Program;
	var locs:Array<ConstantLocation> = [];
	var tus:Array<TextureUnit> = [];

	public function new(driver, desc) {
		this.driver = driver;
		this.desc = desc;

		this.program = driver.gl.createProgram();
		driver.gl.attachShader(program, @:privateAccess cast(desc.vertexShader, Shader).shader);
		driver.gl.attachShader(program, @:privateAccess cast(desc.fragmentShader, Shader).shader);
		var index = 0;
		for (structure in desc.inputLayout) {
			for (attribute in structure.attributes) {
				driver.gl.bindAttribLocation(program, index, attribute.name);
				if (attribute.kind == Float4x4)
					index += 4
				else
					++index;
			}
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
		for (i in locs)
			if (i.name == name || i.name == (name + "[0]"))
				return i;
		Log.warn("Uniform " + name + " not found.");
		@:nullSafety(Off) return new ConstantLocation("invalid", -1, null);
	}

	public function getTextureUnit(name:String):ITextureUnit {
		for (i in tus)
			if (i.name == name)
				return i;
		Log.warn("Sampler " + name + " not found.");
		@:nullSafety(Off) return new TextureUnit("invalid", -1, null);
	}

	public function dispose():Void {
		if (!driver.check())
			return;
		driver.gl.deleteProgram(program);
	}

	public inline function check(?driver:WebGLDriver):Bool {
		if (driver != null) {
			assert(driver == this.driver, "driver mismatch");
		}
		return this.driver.check();
	}
}

class Texture implements ITexture {
	public var desc:TextureDesc;

	var driver:WebGLDriver;
	var texture:js.html.webgl.Texture;
	@:nullSafety(Off) var frameBuffer:Framebuffer;
	@:nullSafety(Off) var renderBuffer:Renderbuffer;

	public function new(driver, desc) {
		this.driver = driver;
		this.desc = desc;

		if (desc.isRenderTarget) {
			texture = driver.gl.createTexture();
			driver.gl.bindTexture(GL.TEXTURE_2D, texture);
			@:nullSafety(Off) driver.gl.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, desc.width, desc.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
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
			@:nullSafety(Off) driver.gl.bindRenderbuffer(GL.RENDERBUFFER, null);
			@:nullSafety(Off) driver.gl.bindFramebuffer(GL.FRAMEBUFFER, null);
			@:nullSafety(Off) driver.gl.bindTexture(GL.TEXTURE_2D, null);
		} else {
			assert(desc.format.match(RGBA), "WebGL only supports rgba textures right now.");
			texture = driver.gl.createTexture();
			driver.gl.bindTexture(GL.TEXTURE_2D, texture);
			@:nullSafety(Off) driver.gl.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, desc.width, desc.height, 0, GL.RGBA, GL.UNSIGNED_BYTE,
				desc.data == null ? null : @:privateAccess desc.data.b);

			driver.gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
			driver.gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
			driver.gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
			driver.gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);

			@:nullSafety(Off) driver.gl.bindTexture(GL.TEXTURE_2D, null);
		}
	}

	public function upload(data:haxe.io.Bytes) {
		if (!desc.isRenderTarget) {
			driver.gl.bindTexture(GL.TEXTURE_2D, texture);
			driver.gl.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, desc.width, desc.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, @:privateAccess data.b);
			@:nullSafety(Off) driver.gl.bindTexture(GL.TEXTURE_2D, null);
		}
	}

	public function dispose() {
		if (driver.check()) {
			driver.gl.deleteTexture(texture);
			if (frameBuffer != null) {
				driver.gl.deleteFramebuffer(frameBuffer);
			}
			if (renderBuffer != null) {
				driver.gl.deleteRenderbuffer(renderBuffer);
			}
		}
	}

	public inline function check(?driver:WebGLDriver):Bool {
		if (driver != null) {
			assert(driver == this.driver, "driver mismatch");
		}
		return this.driver.check();
	}
}

@:allow(arcane.internal.html5)
@:access(arcane.internal.html5)
class WebGLDriver implements IGraphicsDriver {
	public final renderTargetFlipY:Bool = true;
	public final instancedRendering:Bool;
	public final uintIndexBuffers:Bool;

	var canvas:CanvasElement;
	var gl:GL;

	var gl2(get, never):GL2;
	var hasGL2:Bool;

	// var curVertexBuffer:Null<VertexBuffer>;
	var curIndexBuffer:Null<IndexBuffer>;
	var curPipeline:Null<Pipeline>;

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

	public inline function check():Bool {
		return gl != null && !gl.isContextLost();
	}

	public function dispose():Void {
		@:nullSafety(Off) gl = null;
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
			@:nullSafety(Off) if (!enabled_things.exists(cap) || !enabled_things.get(cap)) {
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

	public function createVertexBuffer(desc):IVertexBuffer {
		return new VertexBuffer(this, desc);
	}

	public function createIndexBuffer(desc):IIndexBuffer {
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
			@:nullSafety(Off) gl.bindFramebuffer(GL.FRAMEBUFFER, null);
			gl.viewport(0, 0, canvas.width, canvas.height);
		} else {
			var tex:Texture = cast t;
			assert(tex.driver == this, "driver mismatch");
			gl.bindFramebuffer(GL.FRAMEBUFFER, tex.frameBuffer);
			gl.viewport(0, 0, tex.desc.width, tex.desc.height);
		}
	}

	private var enabledVertexAttribs = 0;

	public function setVertexBuffers(buffers:Array<IVertexBuffer>):Void {
		var vb:Array<VertexBuffer> = cast buffers;
		// assert(vb.driver == this, "driver mismatch");
		// curVertexBuffer = vb;
		for (i in 0...enabledVertexAttribs)
			gl.disableVertexAttribArray(i);
		enabledVertexAttribs = 0;
		for (buffer in vb) {
			gl.bindBuffer(GL.ARRAY_BUFFER, buffer.buf);
			var offset = 0;
			for (i in buffer.layout) {
				gl.enableVertexAttribArray(enabledVertexAttribs + i.index);
				gl.vertexAttribPointer(enabledVertexAttribs + i.index, i.size, GL.FLOAT, false, buffer.stride * 4, i.pos * 4);
				if (instancedRendering) {
					gl2.vertexAttribDivisor(enabledVertexAttribs + i.index, buffer.desc.instanceDataStepRate);
				}
				++offset;
			}
			enabledVertexAttribs += offset;
		}
	}

	public function setVertexBuffer(b:IVertexBuffer):Void {
		var vb:VertexBuffer = cast b;
		// assert(vb.driver == this, "driver mismatch");
		// curVertexBuffer = vb;
		for (i in 0...enabledVertexAttribs)
			gl.disableVertexAttribArray(i);
		gl.bindBuffer(GL.ARRAY_BUFFER, vb.buf);
		enabledVertexAttribs = 0;
		for (i in vb.layout) {
			gl.enableVertexAttribArray(i.index);
			gl.vertexAttribPointer(i.index, i.size, GL.FLOAT, false, vb.stride * 4, i.pos * 4);
			if (instancedRendering) {
				gl2.vertexAttribDivisor(i.index, 0);
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
		if (curIndexBuffer == null)
			throw "Someone forgot to call setIndexBuffer";
		var b = curIndexBuffer;
		gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, b.buf);
		gl.drawElements(GL.TRIANGLES, count == -1 ? b.desc.size : count, b.desc.is32 ? GL.UNSIGNED_INT : GL.UNSIGNED_SHORT, start);
	}

	public function drawInstanced(instanceCount:Int, start:Int = 0, count:Int = -1):Void {
		if (instancedRendering) {
			if (curIndexBuffer == null)
				throw "Someone forgot to call setIndexBuffer";
			var b = curIndexBuffer;
			gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, b.buf);
			gl2.drawElementsInstanced(GL.TRIANGLES, count == -1 ? b.desc.size : count, b.desc.is32 ? GL.UNSIGNED_INT : GL.UNSIGNED_SHORT, start, instanceCount);
		}
	}
}
