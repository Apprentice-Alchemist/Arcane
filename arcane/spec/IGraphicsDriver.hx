package arcane.spec;

interface IVertexBuffer {
    public function upload(arr:Array<Float>):Void;
}

interface IIndexBuffer {
    public function upload(arr:Array<Int>):Void;
}

interface ITexture {

}

interface IGraphicsDriver {
    public function dispose():Void;

    public function begin():Void;
	public function clear(?col:arcane.common.Color, ?depth:Float, ?stencil:Int):Void;
    public function end():Void;
    public function flush():Void;
    public function present():Void;

    public function allocVertexBuffer(size:Int,stride:Int,dyn:Bool):IVertexBuffer;
    public function allocIndexBuffer(count:Int,is32:Bool = true):IIndexBuffer;
    // public function allocTexture():ITexture;

    public function disposeVertexBuffer(obj:Dynamic):Void;
    public function disposeIndexBuffer(obj:Dynamic):Void;
    public function disposeTexture(obj:Dynamic):Void;
}
