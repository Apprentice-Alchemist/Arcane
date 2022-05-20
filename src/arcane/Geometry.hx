package arcane;

import arcane.arrays.UInt16Array;
import arcane.arrays.Int32Array;
import arcane.arrays.Float32Array;
import arcane.gpu.IGPUDevice;

@:nullSafety(Strict)
class Geometry {
	public var points:Array<Point>;
	public var idx:Array<Int>;
	public var uvs:Null<Array<UV>>;

	public function new(points:Array<Point>, ?idx:Array<Int>) {
		this.points = points;
		this.idx = idx == null ? [for (i in 0...points.length) i] : idx;
	}

	public function scale(factor:Float):Void {
		for (p in points) {
			p.x *= factor;
			p.y *= factor;
			p.z *= factor;
		}
	}

	public function translate(x:Float, y:Float, z:Float) {
		for (p in points) {
			p.x += x;
			p.y += y;
			p.z += z;
		}
	}

	public function unindex():Void {
		if (points.length != idx.length) {
			this.points = [for (i in idx) points[i]];
			if (uvs != null) {
				var uvs:Array<UV> = uvs;
				this.uvs = [for (i in idx) uvs[idx[i]]];
			}
			idx = [for (i in 0...points.length) i];
		}
	}

	public function makeBuffers(driver:IGraphicsDriver) {
		var attributes = [{name: "pos", kind: Float3}, {name: "uv", kind: Float2}];
		var ret = {
			vertices: driver.createVertexBuffer({attributes: attributes, size: points.length, dyn: true}),
			indices: driver.createIndexBuffer({size: idx.length, is32: points.length > 65535})
		}
		var vert:Float32Array = ret.vertices.map(0, points.length);
		var p = 0;
		for (i in 0...points.length) {
			vert[p++] = points[i].x;
			vert[p++] = points[i].y;
			vert[p++] = points[i].z;
			if (uvs != null) {
				var uv = uvs[i];
				vert[p++] = uv.u;
				vert[p++] = uv.v;
			} else
				throw "wanted uvs";
		}
		ret.vertices.unmap();
		if (ret.indices.desc.is32) {
			var ind:Int32Array = ret.indices.map(0, idx.length);
			for (i => v in idx)
				ind[i] = v;
			ret.indices.unmap();
			return ret;
		} else {
			var ind:UInt16Array = ret.indices.map(0, idx.length);
			for (i => v in idx)
				ind[i] = v;
			ret.indices.unmap();
			return ret;
		}
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
