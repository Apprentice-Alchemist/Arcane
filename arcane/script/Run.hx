package arcane.script;

import haxe.Json;
import sys.io.File;
import sys.FileSystem;
import haxe.CallStack;

class Run {    
    public static function main(){
        new Run(Sys.args());
    }

    var args:Array<String>;
    var path:String;
    var cmd:String;
    var haxelib_json:Dynamic;
    var VERSION:String;
    public function new(args:Array<String>){
      try{
      this.args = args;
      path = args.pop();
			haxelib_json = Json.parse(File.getContent(ScriptUtils.getLibPath() + "\\haxelib.json"));
			VERSION = haxelib_json.version;
      cmd = args.shift();
      switch cmd {
        case "help": help();
        case "setup": setup();
        case "build": build();
        case "run": run();
        case "test": build(); run();
				default: printInfo();
      }
      Sys.exit(0);
    }catch(e:Dynamic){
			Sys.println(e + CallStack.toString(CallStack.callStack()) + CallStack.toString(CallStack.exceptionStack()));
    }
  }
  public function printInfo(){ColorUtils.print("Arcane",Purple); Sys.println(' CLI Tools v$VERSION');}
    public function build(){

    }
    public function run(){
        if(Sys.command("nekotools") != 0) Sys.println("Neko is required to run js builds.");
    }
    public function help(){
      var cmdlist = ["help","setup","build","run","test"];
      var cmdinfos = [
        "help" => "Print this informations",
        "setup" => "Setup this library, the command line alias and install dependecies",
        "build" => "Build project",
        "run" => "Run project",
        "test" => "Build and Run"
      ];
      printInfo();
      Sys.println("");
      for(o in cmdlist){
        Sys.println(o + " : " + cmdinfos.get(o));
      }
    }
    public function setup(){
      if(ScriptUtils.ask("Do you want to set up the cmd alias?")) setupAlias();
    }
    public function setupAlias(){
		// https://github.com/HaxeFlixel/flixel-tools/blob/dev/src/commands/SetupCommand.hx#L77
      var old = Sys.getCwd();
		  var _new = function(){
      switch Sys.systemName() {
        case "Windows":
          return (Sys.getEnv("HAXEPATH") == null ? "C:\\HaxeToolkit\\haxe" : Sys.getEnv("HAXEPATH"));
        case "Linux":
					return  "/usr/bin";
        case "Mac":
					return "/usr/local/bin";
        case "BMD":
          throw "Wtf is this OS";
        default: throw "Okay. . ";
      }
    }
      Sys.setCwd(_new());
      if(Sys.systemName() == "Windows"){
      File.saveContent("arcane.bat", "@echo off \nhaxelib run arcane  %*");
      }else if(Sys.systemName() == "Linux" || Sys.systemName() == "Mac"){
			File.saveContent("arcane.sh", '#!/bin/sh \nhaxelib run arcane "$ @ "');
      }
      Sys.setCwd(old);
      Sys.println("Alias set to 'arcane'!");      
    }
}
