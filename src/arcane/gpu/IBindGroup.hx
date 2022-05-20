package arcane.gpu;

private enum BindingResource {
	Buffer(buffer:IUniformBuffer);
	Texture(texture:ITexture, sampler:ISampler);
}

@:structInit class BindGroupDescriptor {
	public final layout:IBindGroupLayout;
	public final entries:Array<{
		var binding:Int;
		var resource:BindingResource;
	}>;
}

interface IBindGroup {}
