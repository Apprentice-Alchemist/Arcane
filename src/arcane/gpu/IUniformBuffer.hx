package arcane.gpu;

import arcane.gpu.IGPUDevice;
import arcane.arrays.ArrayBuffer;

@:structInit class UniformBufferDescriptor {
	public final size:Int;
}

interface IUniformBuffer extends IDisposable extends IDescribed<UniformBufferDescriptor> {
	/**
	 * Upload uniform data to the gpu
	 * @param start
	 * @param arr
	 */
	function upload(start:Int, arr:ArrayBuffer):Void;

	function map(start:Int, range:Int):ArrayBuffer;
	function unmap():Void;
}
