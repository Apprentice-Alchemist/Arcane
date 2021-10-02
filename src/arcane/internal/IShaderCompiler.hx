package arcane.internal;

interface IShaderCompiler {
	/**
	 * @param id The name of the shader.
	 * @param source GLSL 450 source
	 * @param vertex Wether it's a vertex shader.
	 * @return haxe.io.Bytes 
	 */
	public function compile(id:String, source:haxe.io.Bytes, stage:asl.Ast.ShaderStage):Void;
}
