package arcane.internal.empty;

import arcane.common.arrays.Int32Array;
import arcane.common.arrays.Float32Array;
import arcane.system.IGraphicsDriver;

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

	var stride:Int = 0;

	public function new(desc) {
		this.desc = desc;
		for (l in desc.layout)
			stride += switch l.kind {
				case Float1: 1;
				case Float2: 2;
				case Float3: 3;
				case Float4: 4;
			}
	}

	public function dispose() {}

	public function upload(start:Int = 0, arr:Array<Float>):Void {}

	public function map(start:Int = 0, range:Int = -1):Float32Array {
		return new Float32Array(range == -1 ? desc.size * stride : range);
	}

	public function unmap():Void {}
}

class IndexBuffer implements IIndexBuffer {
	public var desc(default, null):IndexBufferDesc;

	public function new(desc) {
		this.desc = desc;
	}

	public function dispose() {}

	public function upload(start:Int = 0, arr:Array<Int>):Void {}

	public function map(start:Int = 0, range:Int = -1):Int32Array {
		return new Int32Array(desc.size);
	}

	public function unmap():Void {}
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

	public function new() {}

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

	public function setRenderTarget(?t:ITexture):Void {
		if (t == null) {
			// restore
		} else {
			// set
		}
	}

	public function setPipeline(p:IPipeline):Void {}

	public function setVertexBuffer(b:IVertexBuffer):Void {}

	public function setIndexBuffer(b:IIndexBuffer):Void {}

	public function setTextureUnit(t:ITextureUnit, tex:ITexture):Void {}

	public function setConstantLocation(l:IConstantLocation, f:Array<Float>):Void {}

	public function draw(start:Int = 0, count:Int = -1):Void {}

	public function drawInstanced(instanceCount:Int, start:Int = 0, count:Int = -1):Void {}
}
