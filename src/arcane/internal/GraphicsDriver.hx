package arcane.internal;

import arcane.system.IGraphicsDriver;

#if js
typedef GraphicsDriver = arcane.internal.WebGLDriver;
typedef ConstantLocation = arcane.internal.WebGLDriver.ConstantLocation;
typedef TextureUnit = arcane.internal.WebGLDriver.TextureUnit;
typedef Texture = arcane.internal.WebGLDriver.Texture;
typedef Pipeline = arcane.internal.WebGLDriver.Pipeline;
typedef Shader = arcane.internal.WebGLDriver.Shader;
typedef VertexBuffer = arcane.internal.WebGLDriver.VertexBuffer;
typedef IndexBuffer = arcane.internal.WebGLDriver.IndexBuffer;
#elseif (hl && kinc)
typedef GraphicsDriver = arcane.internal.KincDriver;
typedef ConstantLocation = arcane.internal.KincDriver.CL;
typedef TextureUnit = arcane.internal.KincDriver.TU;
typedef Texture = arcane.internal.KincDriver.Texture;
typedef Pipeline = arcane.internal.KincDriver.Pipeline;
typedef Shader = arcane.internal.KincDriver.Shader;
typedef VertexBuffer = arcane.internal.KincDriver.VertexBuffer;
typedef IndexBuffer = arcane.internal.KincDriver.IndexBuffer;
#else
class TextureUnit implements ITextureUnit {
	public function new() {}
}

class ConstantLocation implements IConstantLocation {
	public function new() {}
}

class Pipeline implements IPipeline {
	public var desc(default, null):PipelineDesc;

	public function new(desc) {
		this.desc = desc;
	}

	public function getConstantLocation(name:String):ConstantLocation {
		return new ConstantLocation();
	}

	public function getTextureUnit(name:String):TextureUnit {
		return new TextureUnit();
	}

	public function dispose() {}
}

class Shader implements IShader {
	public var desc(default, null):ShaderDesc;

	public function new(desc) {
		this.desc = desc;
	}

	public function dispose() {}
}

class VertexBuffer implements IVertexBuffer {
	public var desc(default, null):VertexBufferDesc;

	public function new(desc) {
		this.desc = desc;
	}

	public function dispose() {}

	public function upload(start:Int = 0, arr:Array<Float>):Void {}
}

class IndexBuffer implements IIndexBuffer {
	public var desc(default, null):IndexBufferDesc;

	public function new(desc) {
		this.desc = desc;
	}

	public function dispose() {}

	public function upload(start:Int = 0, arr:Array<Int>):Void {}
}

class Texture implements ITexture {
	public var desc(default, null):TextureDesc;

	public function new(desc) {
		this.desc = desc;
	}

	public function dispose() {}

	public function upload(bytes:haxe.io.Bytes):Void {}
}

class GraphicsDriver implements IGraphicsDriver {
	public final renderTargetFlipY:Bool = false;
	public final instancedRendering:Bool = false;
	public final uintIndexBuffers:Bool = false;

	public function dispose():Void {}

	public function begin():Void {}

	public function clear(?col:arcane.common.Color, ?depth:Float, ?stencil:Int):Void {}

	public function end():Void {}

	public function flush():Void {}

	public function present():Void {}

	public function createVertexBuffer(desc:VertexBufferDesc):VertexBuffer {
		return new VertexBuffer(desc);
	}

	public function createIndexBuffer(desc:IndexBufferDesc):IndexBuffer {
		return new IndexBuffer(desc);
	}

	public function createTexture(desc:TextureDesc):Texture {
		return new Texture(desc);
	}

	public function createShader(desc:ShaderDesc):Shader {
		return new Shader(desc);
	}

	public function createPipeline(desc:PipelineDesc):Pipeline {
		return new Pipeline(desc);
	}

	public function setRenderTarget(?t:Texture):Void {
		if (t == null) {
			// restore
		} else {
			// set
		}
	}

	public function setPipeline(p:Pipeline):Void {}

	public function setVertexBuffer(b:VertexBuffer):Void {}

	public function setIndexBuffer(b:IndexBuffer):Void {}

	public function setTextureUnit(t:TextureUnit, tex:Texture):Void {}

	public function setConstantLocation(l:ConstantLocation, f:Array<Float>):Void {}

	public function draw(start:Int = 0, count:Int = -1):Void {}

	public function drawInstanced(instanceCount:Int, start:Int = 0, count:Int = -1):Void {}
}
#end
