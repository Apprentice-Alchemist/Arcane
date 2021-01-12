package arcane.spec;

enum ShaderKind {
	Vertex;
	Fragment;
}

enum VertexData {
	Float1;
	Float2;
	Float3;
	Float4;
	Float4x4;
}

typedef InputLayout = Array<{var name:String; var kind:VertexData;}>;

@:structInit class PipelineDesc {
	public var blend:Dynamic;
	public var stencil:Dynamic;
	public var inputLayout:InputLayout;
	public var vertexShader:IShader;
	public var fragmentShader:IShader;
}

@:structInit class VertexBufferDesc {
	public var layout:InputLayout;
	public var size:Int;
	public var dyn:Bool = true;
}

@:structInit class IndexBufferDesc {
	public var size:Int;
	public var is32:Bool = false;
}

@:structInit class TextureDesc {
	public var width:Int;
	public var height:Int;
	// public var format:Any;
	@:optional public var data:haxe.io.Bytes;
}

@:structInit class ShaderDesc {
	public var data:haxe.io.Bytes;
	public var kind:ShaderKind;
	@:optional public var fromGlslSrc:Bool = false;
}

interface IDisposable {
	/**
	 * Dispose native resources. The object should not be used after this function has been called.
	 */
	public function dispose():Void;
}

interface IDescribed<T> {
	/**
	 * The descriptor associated with this object.
	 * Editing the descriptors fields after object creation will not have any effect on the object.
	 */
	public var desc(default, null):T;
}

interface ITextureUnit {}
interface IConstantLocation {}

interface IPipeline extends IDisposable extends IDescribed<PipelineDesc> {
	public function getConstantLocation(name:String):IConstantLocation;
	public function getTextureUnit(name:String):ITextureUnit;
}

interface IShader extends IDisposable extends IDescribed<ShaderDesc> {}

interface IVertexBuffer extends IDisposable extends IDescribed<VertexBufferDesc> {
	public function upload(start:Int = 0, arr:Array<Float>):Void;
}

interface IIndexBuffer extends IDisposable extends IDescribed<IndexBufferDesc> {
	public function upload(start:Int = 0, arr:Array<Int>):Void;
}

interface ITexture extends IDisposable extends IDescribed<TextureDesc> {}

interface IGraphicsDriver {
	public function dispose():Void;

	public function begin():Void;
	public function clear(?col:arcane.common.Color, ?depth:Float, ?stencil:Int):Void;
	public function end():Void;
	public function flush():Void;
	public function present():Void;

	public function createVertexBuffer(desc:VertexBufferDesc):IVertexBuffer;
	public function createIndexBuffer(desc:IndexBufferDesc):IIndexBuffer;
	public function createTexture(desc:TextureDesc):ITexture;
	public function createShader(desc:ShaderDesc):IShader;
	public function createPipeline(desc:PipelineDesc):IPipeline;

	public function setPipeline(p:IPipeline):Void;
	public function setVertexBuffer(b:IVertexBuffer):Void;
	public function setIndexBuffer(b:IIndexBuffer):Void;
	public function setTextureUnit(t:ITextureUnit, tex:ITexture):Void;
	public function setConstantLocation(l:IConstantLocation, f:Array<arcane.FastFloat>):Void;
	public function draw():Void;
}
