package arcane.gpu;

import arcane.gpu.IGPUDevice;
import arcane.arrays.ArrayBuffer;
import arcane.gpu.IRenderPipeline;

@:structInit class VertexBufferDescriptor {
	public final attributes:Array<VertexAttribute>;
	public final instanceDataStepRate:Int = 0;
	public final size:Int;
	public final dyn:Bool = true;
}

interface IVertexBuffer extends IDisposable extends IDescribed<VertexBufferDescriptor> {
	/**
	 * Upload vertex data to the gpu
	 * @param start
	 * @param arr
	 */
	function upload(start:Int, arr:ArrayBuffer):Void;

	function map(start:Int, range:Int):ArrayBuffer;
	function unmap():Void;

	function stride():Int;
}
