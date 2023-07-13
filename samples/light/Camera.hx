import arcane.util.Math;

@:nullSafety
class Camera {
	public var pos(default, null):Vector3;
	public var front(default, null):Vector3 = new Vector3(0,0,-1);
	public var up(default, null):Vector3;
	public var right(default, null):Vector3;
	public var worldUp(default, null):Vector3;

	public var yaw(default, null):Float;
	public var pitch(default, null):Float;

	public var movementSpeed(default, null):Float = 2.5;
	public var mouseSensitivity(default, null):Float = 0.1;
	public var zoom(default, null):Float = 0.45;

	public function new(pos:Vector3, up:Vector3, yaw:Float, pitch:Float) {
		this.pos = pos;
		this.worldUp = up;
		this.yaw = yaw;
		this.pitch = pitch;

		updateCameraVectors();
	}

	public function getViewMatrix():Matrix4 {
		return Matrix4.lookAt(pos, pos + front, up);
	}

	static function radians(deg:Float) {
		return (deg * Math.PI) / 180;
	}

	inline function updateCameraVectors() {
		this.front = new Vector3(Math.cos(radians(yaw)) * Math.cos(radians(pitch)), Math.sin(radians(pitch)), Math.sin(radians(yaw)) * Math.cos(radians(pitch))).normalize();

		this.right = front.cross(worldUp).normalize();
		this.up = this.right.cross(front).normalize();
	}
}