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
	function get_vertex_src():String return "";

	function get_fragment_src():String return "";

	public function new() {}

	public function make(d:IGraphicsDriver) {
		return {
			vertex: getVertex(d),
			fragment: getFragment(d)
		}
	}

	public function getVertex(driver:IGraphicsDriver):IShader {
		return driver.createShader({data: Bytes.ofHex(get_vertex_src()), kind: Vertex});
	}

	public function getFragment(driver:IGraphicsDriver):IShader {
		return driver.createShader({data: Bytes.ofHex(get_fragment_src()), kind: Fragment});
	}
}
