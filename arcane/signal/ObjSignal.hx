package arcane.signal;

class ObjSignal<T> extends Signal {
	public final value:T;

	override public function new(name:String, value:T) {
		super(name);
		this.value = value;
	}
}
