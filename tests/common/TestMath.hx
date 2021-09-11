package common;

import arcane.util.Math;

class TestMath extends utest.Test {
	// TODO : Vector and Matrix3 stuff. (Maybe.)
	function testMat4() {
		assert(Matrix4.identity() * Matrix4.identity() == Matrix4.identity());
		assert(Matrix4.identity() + Matrix4.identity() == new Matrix4(
			2, 0, 0, 0,
			0, 2, 0, 0,
			0, 0, 2, 0,
			0, 0, 0, 2
		));
		assert(Matrix4.identity() - Matrix4.identity() == Matrix4.empty());
		assert(Matrix4.identity().trace() == 4);
		assert(Matrix4.identity() * 2 == new Matrix4(
			2, 0, 0, 0,
			0, 2, 0, 0,
			0, 0, 2, 0,
			0, 0, 0, 2
		));
		assert(Matrix4.identity() + 2 == new Matrix4(
			3, 2, 2, 2,
			2, 3, 2, 2,
			2, 2, 3, 2,
			2, 2, 2, 3
		));
		assert(new Matrix4(
			3, 2, 2, 2,
			2, 3, 2, 2,
			2, 2, 3, 2,
			2, 2, 2, 3
		) * new Matrix4(
			3, 2, 2, 9,
			2, 5, 2, 2,
			1, 2, 3, 2,
			2, 2, 2, 3
		) == new Matrix4(
			19, 24, 20, 41,
			18, 27, 20, 34,
			17, 24, 21, 34,
			18, 24, 20, 35
		));
		assert(new Matrix4(
			3, 2, 2, 2,
			2, 3, 2, 2,
			2, 2, 3, 2,
			2, 2, 2, 3
		) * new Vector4(3, 2, 5, 9) == new Vector4(41, 40, 43, 47));
	}
}
