package arcane.gpu;

import arcane.gpu.IShaderModule;

private enum SamplerBindingType {
	Filtering;
	NonFiltering;
	Comparison;
}

private enum BindingKind {
	Buffer(hasDynamicOffset:Bool, minBindingSize:Int);
	// Sampler(type:SamplerBindingType);
	Texture(sampler_type:SamplerBindingType);
}

@:structInit class BindGroupLayoutDescriptor {
	public final entries:Array<{
		var visibility:ShaderStage;
		var binding:Int;
		var kind:BindingKind;
	}>;
}

interface IBindGroupLayout {}
