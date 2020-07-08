package arcane.signal;

class ObjSignal<T> extends Signal {
	public final value:T;

	override public function new<C:T>(name:String, value:C) {
		super(name);
		this.value = value;
	}
}
