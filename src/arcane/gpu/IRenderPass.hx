package arcane.gpu;

import arcane.util.Color;

enum LoadOp {
	Clear(?color:Color);
	Load;
}

enum StoreOp {
	Store;
	Discard;
}

@:structInit class ColorAttachment {
	public final texture:ITexture;

	public final load:LoadOp;
	public final store:StoreOp;
}

@:structInit class RenderPassDescriptor {
	public final colorAttachments:Array<ColorAttachment>;
	// public final stencilAttachment:StencilAttachment;
	// public final depthAttachment:DepthAttachment;
}

interface IRenderPass {
	function setPipeline(p:IRenderPipeline):Void;
	function setVertexBuffer(b:IVertexBuffer):Void;
	function setVertexBuffers(buffers:Array<IVertexBuffer>):Void;
	function setIndexBuffer(b:IIndexBuffer):Void;
	function setBindGroup(index:Int, group:IBindGroup):Void;

	function draw(start:Int, count:Int):Void;
	function drawInstanced(instanceCount:Int, start:Int, count:Int):Void;

	function end():Void;
}
