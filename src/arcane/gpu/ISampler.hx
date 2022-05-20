package arcane.gpu;

import arcane.gpu.IRenderPipeline;

@:structInit class SamplerDescriptor {
	public final uAddressing:AddressMode = Clamp;
	public final vAddressing:AddressMode = Clamp;
	public final wAddressing:AddressMode = Clamp;

	public final magFilter:FilterMode = Nearest;
	public final minFilter:FilterMode = Nearest;
	public final mipFilter:FilterMode = Nearest;

	public final lodMinClamp:Float = 0;
	public final lodMaxClamp:Float = 32;

	public final compare:Null<Compare> = null;
	public final maxAnisotropy:Int = 1;
}

interface ISampler {}
