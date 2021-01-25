package asl;

import haxe.io.Bytes;
import arcane.spec.IGraphicsDriver;
#if (!eval||macro)
@:autoBuild(asl.Macros.buildShader())
#end
@:allow(arcane)
class Shader {
	private var vertex_src(get, never):String;

	private function get_vertex_src():String return "";

	private var fragment_src(get, never):String;

	private function get_fragment_src():String return "";

	public function new() {}

	public function getVertex(driver:IGraphicsDriver) {
		return driver.createShader({data: Bytes.ofHex(vertex_src), kind: Vertex});
	}

	public function getFragment(driver:IGraphicsDriver) {
		return driver.createShader({data: Bytes.ofHex(fragment_src), kind: Fragment});
	}
}
