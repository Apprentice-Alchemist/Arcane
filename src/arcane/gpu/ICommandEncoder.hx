package arcane.gpu;

import arcane.gpu.IComputePass;
import arcane.gpu.IRenderPass;

interface ICommandEncoder {
	function beginComputePass(desc:ComputePassDescriptor):IComputePass;
	function beginRenderPass(desc:RenderPassDescriptor):IRenderPass;
	function finish():ICommandBuffer;
}
