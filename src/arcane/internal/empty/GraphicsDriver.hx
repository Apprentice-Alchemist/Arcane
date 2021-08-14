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

	var buf_stride:Int = 0;

	public function new(desc) {
		this.desc = desc;
		for (l in desc.attributes)
			buf_stride += switch l.kind {
				case Float1: 1;
				case Float2: 2;
				case Float3: 3;
				case Float4: 4;
				case Float4x4: 16;
			}
	}

	public function dispose() {}

	public function stride():Int {
		return buf_stride;
	}

	public function upload(start:Int, arr:Float32Array):Void {}

	public function map(start:Int, range:Int):Float32Array {
		return new Float32Array(range == -1 ? desc.size * buf_stride : range);
	}

	public function unmap():Void {}
}

class IndexBuffer implements IIndexBuffer {
	public var desc(default, null):IndexBufferDesc;

	public function new(desc) {
		this.desc = desc;
	}

	public function dispose() {}

	public function upload(start:Int, arr:Int32Array):Void {}

	public function map(start:Int, range:Int):Int32Array {
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

class RenderPass implements IRenderPass {
	public function new(desc:RenderPassDesc) {}

	public function setPipeline(p:IPipeline) {}

	public function setVertexBuffer(b:IVertexBuffer) {}

	public function setVertexBuffers(buffers:Array<IVertexBuffer>) {}

	public function setIndexBuffer(b:IIndexBuffer) {}

	public function setTextureUnit(t:ITextureUnit, tex:ITexture) {}

	public function setConstantLocation(l:IConstantLocation, f:Float32Array) {}

	public function draw(start:Int, count:Int) {}

	public function drawInstanced(instanceCount:Int, start:Int, count:Int) {}

	public function end() {}
}

class GraphicsDriver implements IGraphicsDriver {
	public final renderTargetFlipY:Bool = false;
	public final instancedRendering:Bool = false;
	public final uintIndexBuffers:Bool = false;

	public function new() {}

	public function getName(details:Bool = false) {
		return "Empty Driver";
	}

	public function dispose():Void {}

	public function begin():Void {}

	public function end():Void {}

	public function flush():Void {}

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

	public function beginRenderPass(desc:RenderPassDesc):IRenderPass {
		return new RenderPass(desc);
	}
}
