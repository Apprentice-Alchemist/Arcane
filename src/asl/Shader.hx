package asl;

import arcane.system.IGraphicsDriver;
import haxe.io.Bytes;

/**
 * Shader base class, extend and use @:vertex and @:fragment metadata to supply glsl source code.
 * The glsl code will be converted to the appropriate shader language at compile time.
 */
#if !macro
@:autoBuild(asl.Macros.buildShader())
#end
class Shader {
	public final id:String;

	public function new(id:String) {
		this.id = id;
	}

	public function make(d:IGraphicsDriver) {
		return {
			vertex: d.createShader({id: id, kind: Vertex}),
			fragment: d.createShader({id: id, kind: Fragment})
		}
	}
}
