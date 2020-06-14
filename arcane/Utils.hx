package arcane;

class Utils{
    public static function parseInt(i:String):Int{
        if(i == null) return 0;
        var tmp = Std.parseInt(i);
        if(tmp == null) return 0;
        return tmp;
    }
    public static function parseFloat(f:String):Float{
        if(f == null) return 0.0;
        var tmp = Std.parseFloat(f);
        if(tmp == null || Math.isNaN(tmp)) return 0.0;
        return tmp;
    }
    public static function int(f:Float):Int{
        if(f == null || !Math.isFinite(f)) return 0;
        return Std.int(f);
    }
}