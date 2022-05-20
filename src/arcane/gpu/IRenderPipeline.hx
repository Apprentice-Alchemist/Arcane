package arcane.gpu;

import arcane.gpu.IGPUDevice;

enum VertexData {
	Float1;
	Float2;
	Float3;
	Float4;
	Float4x4;
}

enum Face {
	None;
	Back;
	Front;
	Both;
}

enum Blend {
	One;
	Zero;
	SrcAlpha;
	SrcColor;
	DstAlpha;
	DstColor;
	OneMinusSrcAlpha;
	OneMinusSrcColor;
	OneMinusDstAlpha;
	OneMinusDstColor;
}

enum Compare {
	Always;
	Never;
	Equal;
	NotEqual;
	Greater;
	GreaterEqual;
	Less;
	LessEqual;
}

enum StencilOp {
	Keep;
	Zero;
	Replace;
	Increment;
	IncrementWrap;
	Decrement;
	DecrementWrap;
	Invert;
}

enum FilterMode {
	Nearest;
	Linear;
}

enum AddressMode {
	Clamp;
	Repeat;
	Mirrored;
}

enum Operation {
	Add;
	Sub;
	ReverseSub;
	Min;
	Max;
}

typedef VertexAttribute = {
	final name:String;
	final kind:VertexData;
}

typedef InputLayout = Array<{
	final instanced:Bool;
	final attributes:Array<VertexAttribute>;
}>;

@:structInit class BlendDescriptor {
	public final src:Blend = One;
	public final dst:Blend = Zero;
	public final alphaSrc:Blend = One;
	public final alphaDst:Blend = Zero;
	public final op:Operation = Add;
	public final alphaOp:Operation = Add;
}

@:structInit class StencilDescriptor {
	public final readMask:Int = 0xff;
	public final writeMask:Int = 0xff;
	public final reference:Int = 0;

	public final frontTest:Compare = Always;
	public final frontPass:StencilOp = Keep;
	public final frontSTfail:StencilOp = Keep;
	public final frontDPfail:StencilOp = Keep;

	public final backTest:Compare = Always;
	public final backPass:StencilOp = Keep;
	public final backSTfail:StencilOp = Keep;
	public final backDPfail:StencilOp = Keep;
}

@:structInit class RenderPipelineDescriptor {
	public final vertexShader:IShaderModule;
	public final fragmentShader:IShaderModule;
	public final inputLayout:InputLayout;
	public final layout:Array<IBindGroupLayout> = [];
	public final blend:BlendDescriptor = {};
	public final stencil:StencilDescriptor = {};
	public final culling:Face = None;
	public final depthWrite:Bool = false;
	public final depthTest:Compare = Always;
}

interface IRenderPipeline extends IDisposable extends IDescribed<RenderPipelineDescriptor> {}
