package arcane.gpu;

import arcane.gpu.IGPUDevice;
import asl.Ast;

enum abstract ShaderStage(Int) {
	var Vertex = 0x1;
	var Fragment = 0x2;
	var Compute = 0x4;

	@:op(A | B) static function and(a:ShaderStage, b:ShaderStage):ShaderStage;
}

@:structInit class ShaderDescriptor {
	public final module:ShaderModule;
}

interface IShaderModule extends IDisposable extends IDescribed<ShaderDescriptor> {}
