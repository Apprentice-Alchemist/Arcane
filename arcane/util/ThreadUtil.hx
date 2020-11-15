package arcane.util;

class ThreadUtil {
    public static function megaPop<T>(d:sys.thread.Deque<T>):Array<T> {
        var ret = [];
        var val:T = d.pop(false);
        while(val != null){
            ret.push(val);
            if(ret.length > 100) break;
            val = d.pop(false);
        }
        return ret;
    }
}