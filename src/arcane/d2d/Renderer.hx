package arcane.d2d;

import arcane.spec.IGraphicsDriver;

class Renderer {
	var driver:IGraphicsDriver;
	var pipeline:IPipeline;
	var quad_indexes:IIndexBuffer;

	public function new(driver) {
		this.driver = driver;
		makeQuadBuffer();
		var shader = new Base2DShader();
		var vs = shader.getVertex(driver);
		var fs = shader.getFragment(driver);
		pipeline = driver.createPipeline({
			vertexShader: vs,
			fragmentShader: fs,
			inputLayout: [
				{
					name: "pos",
					kind: Float2
				},
				{
					name: "uv",
					kind: Float2
				},
				{
					name: "color",
					kind: Float4
				}
			],
			depthTest: Always
		});
	}

	inline function makeQuadBuffer() {
		final SIZE = 65533;
		final indices:Array<Int> = [];
		for (i in 0...SIZE >> 2) {
			var k = i << 2;
			indices.push(k);
			indices.push(k + 1);
			indices.push(k + 2);
			indices.push(k + 2);
			indices.push(k + 1);
			indices.push(k + 3);
		}
		indices.push(SIZE);
		quad_indexes = driver.createIndexBuffer({is32: true, size: SIZE});
		quad_indexes.upload(indices);
	}
}
