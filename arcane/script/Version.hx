package script;


abstract Version(String) from String to String {
    public static function new(s:String){

    }
    @:from static public function fromString(s:String){
        return new Version(s);
    }
    @:to public function toString(){

    }
}