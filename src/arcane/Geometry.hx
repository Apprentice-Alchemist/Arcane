package arcane;

import arcane.spec.IGraphicsDriver;

@:nullSafety
class Geometry {
	public var points:Array<Point>;
	public var uvs:Null<Array<UV>>;
	public var idx:Null<Array<Int>>;

	public function new(points:Array<Point>, ?idx:Array<Int>) {
		assert(points != null);
		this.points = points;
		this.idx = idx;
	}

	public function scale(factor:Float):Void {
		for (p in points) {
			p.x *= factor;
			p.y *= factor;
			p.z *= factor;
		}
	}
	
	public function unindex():Void {
		if (idx != null && points != null && points.length != idx.length) {
			var p = [];
			for (i in 0...idx.length)
				p.push(points[idx[i]].clone());

			var nuvs:Null<Array<UV>> = null;
			if (uvs != null) {
				nuvs = [];
				for (i in 0...idx.length)
					nuvs.push(uvs[idx[i]].clone());
			}
			points = p;
			uvs = nuvs;
			idx = null;
		}
	}

	public function makeBuffers(driver:IGraphicsDriver):{
		var vertex:IVertexBuffer;
		var index:IIndexBuffer;
	} {
		var layout:InputLayout = [];
		layout.push({name: "pos", kind: Float3});
		if (uvs != null)
			layout.push({name: "uv", kind: Float2});

		assert(points != null);
		if (points == null)
			throw "";
		var ret = {
			vertex: driver.createVertexBuffer({layout: layout, size: points.length, dyn: false}),
			index: driver.createIndexBuffer({size: idx == null ? points.length : idx.length, is32: points.length > (Math.pow(2, 8) - 1)})
		}
		var vert = [];
		for (i in 0...points.length) {
			vert.push(points[i].x);
			vert.push(points[i].y);
			vert.push(points[i].z);
			if (uvs != null) {
				vert.push(uvs[i].u);
				vert.push(uvs[i].v);
			}
		}
		ret.index.upload(if (idx == null) [for (i in 0...points.length) i] else idx);
		ret.vertex.upload(vert);
		return ret;
	}
}

class Point {
	public var x:Float;
	public var y:Float;
	public var z:Float;

	public inline function new(x:Float, y:Float, z:Float) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public inline function clone() {
		return new Point(x, y, z);
	}
}

class UV {
	public var u:Float;
	public var v:Float;

	public inline function new(u:Float, v:Float) {
		this.u = u;
		this.v = v;
	}

	public inline function clone() {
		return new UV(u, v);
	}
}