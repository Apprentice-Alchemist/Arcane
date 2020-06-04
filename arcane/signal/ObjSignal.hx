package arcane.signal;

class ObjSignal extends Signal{
    public final value:Dynamic;
    override public function new(name:String,value:Dynamic) {
        super(name);
        this.value = value;
    }
}