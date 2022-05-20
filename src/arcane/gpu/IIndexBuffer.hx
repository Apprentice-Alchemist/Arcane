package arcane.gpu;

import arcane.gpu.IGPUDevice;
import arcane.arrays.ArrayBuffer;

@:structInit class IndexBufferDescriptor {
	public final size:Int;
	public final is32:Bool = true;
}

interface IIndexBuffer extends IDisposable extends IDescribed<IndexBufferDescriptor> {
	/**
	 * Upload index data to the gpu
	 * @param start
	 * @param arr
	 */
	function upload(start:Int, arr:ArrayBuffer):Void;

	function map(start:Int, range:Int):ArrayBuffer;
	function unmap():Void;
}
