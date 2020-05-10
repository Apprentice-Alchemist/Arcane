package script;

import sys.io.Process;

class ScriptUtils{
    public static function ask(question:String):Bool{
        Sys.println(question + "[y|n]");
        while(true){
            var t = Sys.stdin().readLine();
            switch t {
                case "y":return true;
                case "n": return false;
                default: throw "Not a valid answer";
            }
        }
    }
    public static function getLibPath():String{
        while(true){
            var process = new Process("haxelib",["libpath","Arcane"]);
            var path = process.stdout.readLine();
            process.close();
            return path;
        }
    }
}