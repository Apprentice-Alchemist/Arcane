package arcane.gpu;

@:structInit class ComputePassDescriptor {}

interface IComputePass {
	function setBindGroup(index:Int, group:IBindGroup):Void;
	function setPipeline(p:IComputePipeline):Void;
	function dispatch(x:Int, y:Int, z:Int):Void;

	function end():Void;
}
