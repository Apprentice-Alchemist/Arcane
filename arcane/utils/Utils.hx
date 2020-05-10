package arcane.utils;

import haxe.CallStack;

class Utils{
    public static function makeCallStack(){
        return CallStack.toString(CallStack.exceptionStack());
    }
}