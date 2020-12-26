package arcane.backend.kinc;

import kinc.g4.Graphics4;
import arcane.spec.IGraphicsDriver;

class GraphicsDriver implements IGraphicsDriver {
    private var window:Int;
    public function new(window:Int = 0) this.window = window;

	public function dispose():Void {};

	public function begin():Void Graphics4.begin(window);
	public function clear(r:Float, g:Float, b:Float, a:Float):Void Graphics4.clear(1,0x00ff00,0,0);
	public function end():Void Graphics4.end(0);
	public function flush():Void Graphics4.flush();
	public function present():Void Graphics4.swapBuffers();

	public function allocVertexBuffer(...args:Dynamic):Dynamic return null;
	public function allocIndexBuffer(...args:Dynamic):Dynamic return null;
	public function allocTexture(...args:Dynamic):Dynamic return null;

	public function disposeVertexBuffer(obj:Dynamic):Void {};
	public function disposeIndexBuffer(obj:Dynamic):Void {};
	public function disposeTexture(obj:Dynamic):Void {};
}