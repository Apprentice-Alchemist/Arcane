package asl;

import arcane.gpu.IGPUDevice;
import haxe.io.Bytes;
import asl.Ast;

/**
 * Shader base class, extend and use @:vertex and @:fragment metadata to supply glsl source code.
 * The glsl code will be converted to the appropriate shader language at compile time.
 */
#if !macro
@:autoBuild(asl.Macros.buildShader())
#end
class Shader {
	public final id:String;
	public final vertex:Null<ShaderModule>;
	public final fragment:Null<ShaderModule>;
	public final compute:Null<ShaderModule>;

	public function new(id:String, vertex:Null<ShaderModule>, fragment:Null<ShaderModule>, compute:Null<ShaderModule>) {
		this.id = id;
		this.vertex = vertex;
		this.fragment = fragment;
		this.compute = compute;
	}

	public function make(d:IGPUDevice) {
		return {
			vertex: vertex == null ? null : d.createShader({module: vertex}),
			fragment: fragment == null ? null : d.createShader({module: fragment}),
			compute: compute == null ? null : d.createShader({module: compute})
		}
	}
}
