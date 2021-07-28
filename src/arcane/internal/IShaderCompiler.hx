package arcane.internal;

interface IShaderCompiler {
	/**
	 * @param id The name of the shader.
	 * @param source Glsl 450 source
	 * @param vertex Wether it's a vertex shader.
	 * @return haxe.io.Bytes 
	 */
	public function compile(id:String, source:haxe.io.Bytes, vertex:Bool):Void;
	}
