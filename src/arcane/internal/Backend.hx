package arcane.internal;

class Backend {
    public var id:String;
	public function new(id:String) {
        this.id = id;
    }
    public inline function toString()
        return id;
}