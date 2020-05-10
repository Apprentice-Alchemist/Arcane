package arcane.adv.macros;

import haxe.macro.Compiler;


class Macros{
    #if macro
    public static function runAll(){
        makeDefines();
    }
    public static function makeDefines(){
        if(!haxe.macro.Context.defined("hscriptPos")) Compiler.define("hscriptPos");
    }
	#end
}
