package arcane.backend.html5;

import js.html.webgl.Program;
import js.lib.Uint16Array;
import js.html.webgl.Buffer;
import js.html.webgl.GL;
import js.html.CanvasElement;
import arcane.spec.IGraphicsDriver;
import arcane.Utils.assert;

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
				case Float4x4: 0;
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

private class Pipeline implements IPipeline {
	public var desc(default, null):PipelineDesc;

	var driver:WebGLDriver;
	var program:Program;

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
		driver.gl.validateProgram(program);
		if(driver.gl.getProgramParameter(program, GL.LINK_STATUS) != 1) {
			throw "WebGL Program Linking failure : " + driver.gl.getProgramInfoLog(program);
		}
	}

	public function getConstantLocation(name:String):IConstantLocation {
		if(!driver.check() || program == null)
			return null;
		driver.gl.getUniformLocation(program, name);
		return null;
	}

	public function getTextureUnit(name:String):ITextureUnit {
		if(!driver.check() || program == null)
			return null;
		return null;
	}

	public function dispose():Void {
		if(!driver.check() || program == null)
			return;
		driver.gl.deleteProgram(program);
		program = null;
	}
}

@:allow(arcane.backend.html5)
@:access(arcane.backend.html5)
class WebGLDriver implements IGraphicsDriver {
	var canvas:CanvasElement;
	var gl:GL;

	var curVertexBuffer:VertexBuffer;
	var curIndexBuffer:IndexBuffer;
	var curPipeline:Pipeline;

	public function new(gl:GL, canvas:CanvasElement) {
		this.canvas = canvas;
		this.gl = gl;
	}

	public function check():Bool return gl != null && !gl.isContextLost();

	public function dispose():Void {
		gl = null;
	}

	public function begin():Void {}

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

	public function end():Void {
		// gl.finish();
	}

	public function flush():Void {
		// gl.flush();
	}

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
			return null;

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

	public function setPipeline(p:IPipeline):Void {
		var state:Pipeline = cast p;
		if(state.driver != this)
			throw "Driver mismatch";
		gl.validateProgram(state.program);
		gl.useProgram(state.program);
		curPipeline = state;
	}

	private var enabledVertexAttribs = 0;

	public function setVertexBuffer(b:IVertexBuffer):Void {
		var vb:VertexBuffer = cast b;
		if(vb.driver != this)
			throw "Driver mismatch";
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
		if(ib.driver != this)
			throw "Driver mismatch";
		curIndexBuffer = ib;
	}

	public function setTextureUnit(t:ITextureUnit, tex:ITexture):Void {}

	public function setConstantLocation(l:IConstantLocation, f:Array<arcane.FastFloat>):Void {}

	public function draw():Void {
		gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, curIndexBuffer.buf);
		gl.drawElements(GL.TRIANGLES, curIndexBuffer.desc.size, GL.UNSIGNED_SHORT, 0);
	}
}
