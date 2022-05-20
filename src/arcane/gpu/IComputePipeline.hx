package arcane.gpu;

import arcane.gpu.IGPUDevice;

@:structInit class ComputePipelineDescriptor {
	public final shader:IShaderModule;
}

interface IComputePipeline extends IDisposable extends IDescribed<ComputePipelineDescriptor> {}
