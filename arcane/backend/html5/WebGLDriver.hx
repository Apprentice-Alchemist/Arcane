package arcane.backend.html5;

import js.html.webgl.Buffer;
import js.html.webgl.GL;
import js.html.CanvasElement;
import arcane.spec.IGraphicsDriver;

private class VertexBuffer implements IVertexBuffer {
	private var buf:Buffer;
	private var driver:WebGLDriver;

	public function new(driver:WebGLDriver, buf:Buffer) {
		this.buf = buf;
		this.driver = driver;
	}

	public function upload(arr:Array<Float>):Void {
		var arr = js.lib.Float32Array.from(arr);
		driver.gl.bindBuffer(GL.ARRAY_BUFFER, buf);
		driver.gl.bufferSubData(GL.ARRAY_BUFFER, 0, arr.buffer);
		driver.gl.bindBuffer(GL.ARRAY_BUFFER, null);
	}
}

private class IndexBuffer implements IIndexBuffer {
	private var buf:Buffer;
	private var driver:WebGLDriver;
	private var is32:Bool;

	public function new(driver:WebGLDriver, buf:Buffer,is32:Bool) {
		this.buf = buf;
		this.driver = driver;
	}

	public function upload(arr:Array<Int>):Void {
		var arr = js.lib.Int32Array.from(arr);
		driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
		driver.gl.bufferSubData(GL.ELEMENT_ARRAY_BUFFER, 0, arr.buffer);
		driver.gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
	}
}

@:allow(arcane.backend.html)
class WebGLDriver implements IGraphicsDriver {
	public var canvas:CanvasElement;
	public var gl:GL;

	public function new(canvas:CanvasElement) {
		this.canvas = canvas;
		this.gl = untyped canvas.getContext("webgl") || canvas.getContext("experimental-webgl");
	}

	public function dispose():Void {}

	public function begin():Void {}

	public function clear(?col:arcane.common.Color,?depth:Float,?stencil:Int):Void {
		var bits:arcane.common.IntFlags = 0;
		if(col == null) col = 0x000000ff;
		gl.clearColor(col.r, col.g, col.b, col.a);
		bits.addFlag(GL.COLOR_BUFFER_BIT);
		if(depth != null){
			gl.clearDepth(depth);
			bits.addFlag(GL.DEPTH_BUFFER_BIT);
		}
		if(stencil != null) {
			gl.clearStencil(stencil);
			bits.addFlag(GL.STENCIL_BUFFER_BIT);
		}
		gl.clear(bits);
	}

	public function end():Void {}

	public function flush():Void {}

	public function present():Void {}

	public function allocVertexBuffer(size:Int, stride:Int, dyn:Bool):IVertexBuffer {
		var buf = gl.createBuffer();
		gl.bindBuffer(GL.ARRAY_BUFFER, buf);
		gl.bufferData(GL.ARRAY_BUFFER, size * stride * 4, dyn ? GL.DYNAMIC_DRAW : GL.STATIC_DRAW);
		gl.bindBuffer(GL.ARRAY_BUFFER, null);
		return new VertexBuffer(this, buf);
	};

	public function allocIndexBuffer(count:Int, is32:Bool = true):IIndexBuffer {
		var buf = gl.createBuffer();
		var size = is32 ? 4 : 2;
		gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
		gl.bufferData(GL.ELEMENT_ARRAY_BUFFER, count * size, GL.STATIC_DRAW);
		gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
		return new IndexBuffer(this,buf,is32);
	}

	public function allocTexture(...args:Dynamic):Dynamic return null;

	public function disposeVertexBuffer(obj:Dynamic):Void {};

	public function disposeIndexBuffer(obj:Dynamic):Void {};

	public function disposeTexture(obj:Dynamic):Void {};
}
