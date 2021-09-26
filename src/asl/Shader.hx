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
	public final vertex:Null<ShaderModule>;
	public final fragment:Null<ShaderModule>;
	public final compute:Null<ShaderModule>;

	public function new(id:String, vertex:Null<ShaderModule>, fragment:Null<ShaderModule>, compute:Null<ShaderModule>) {
		this.id = id;
		this.vertex = vertex;
		this.fragment = fragment;
		this.compute = compute;
	}

	public function make(d:IGraphicsDriver) {
		return {
			vertex: vertex == null ? null : d.createShader({id: id, kind: Vertex}),
			fragment: fragment == null ? null : d.createShader({id: id, kind: Fragment}),
			compute: compute == null ? null : d.createShader({id: id, kind: Compute})
		}
	}
}
