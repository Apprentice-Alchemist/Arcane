package arcane.spec;

interface IGraphicsDriver {
    public function dispose():Void;

    public function begin():Void;
    public function clear(r:Float,g:Float,b:Float,a:Float):Void;
    public function end():Void;
    public function flush():Void;
    public function present():Void;

    public function allocVertexBuffer(...args:Dynamic):Dynamic;
    public function allocIndexBuffer(...args:Dynamic):Dynamic;
    public function allocTexture(...args:Dynamic):Dynamic;

    public function disposeVertexBuffer(obj:Dynamic):Void;
    public function disposeIndexBuffer(obj:Dynamic):Void;
    public function disposeTexture(obj:Dynamic):Void;
}
