package asl;

import arcane.system.IGraphicsDriver;
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
	public final vertex:ShaderModule;
	public final fragment:ShaderModule;

	public function new(id:String, vertex:ShaderModule, fragment:ShaderModule) {
		this.id = id;
		this.vertex = vertex;
		this.fragment = fragment;
	}

	public function make(d:IGraphicsDriver) {
		return {
			vertex: d.createShader({id: id, kind: Vertex}),
			fragment: d.createShader({id: id, kind: Fragment})
		}
	}
}
