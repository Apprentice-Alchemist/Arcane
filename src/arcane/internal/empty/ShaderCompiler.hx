package arcane.internal.empty;

import asl.Ast.ShaderStage;
import haxe.io.Bytes;

class ShaderCompiler implements IShaderCompiler {
	public function new() {}

	public function compile(id:String, source:Bytes, stage:ShaderStage):Void {}
}
