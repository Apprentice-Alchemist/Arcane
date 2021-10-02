package arcane.internal;

import arcane.util.Version;
#if macro
import sys.FileSystem;
import haxe.io.Bytes;
import haxe.Json;
import sys.io.File;
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Expr;

using haxe.macro.Tools;
#end

class Macros {
	public macro static function initManifest() {
		var path = Context.defined("resourcesPath") ? Context.definedValue("resourcesPath") : "res";
		var files = [];
		function readRec(f:Array<String>, basePath:String) {
			for (f1 in f) {
				var p = haxe.io.Path.normalize(basePath + "/" + f1);
				if (sys.FileSystem.isDirectory(p)) {
					readRec(sys.FileSystem.readDirectory(p), p);
				} else {
					files.push(p);
				}
			}
		}
		readRec(sys.FileSystem.readDirectory(path), path);
		return macro $v{files};
	}

	public static macro function getVersion(full_hash:Bool = false):ExprOf<arcane.util.Version> {
		#if display
		return macro("0.0.0" : Version);
		#end
		if (Context.defined("display"))
			return macro("0.0.0" : Version);
		var arcane = findArcane();
		var haxelib_ver:Version = new Version("0.0.0");
		if (FileSystem.exists(arcane + "/haxelib.json")) {
			var c = File.getContent(arcane + "/haxelib.json");
			var json:{
				version:String
			} = Json.parse(c);
			haxelib_ver = new Version(json.version);
		}
		var git:Null<String> = null;
		{
			var proc = cmd("git", ["rev-parse", "HEAD"]);
			if (proc.code == 0) {
				git = proc.stdout.toString();
				if (!full_hash)
					git = git.substr(0, 8);
			}
		}

		haxelib_ver.build = git;
		return macro($v{haxelib_ver.toString()} : arcane.util.Version);
	}

	#if macro
	@:persistent static var shaderCompiler:Null<IShaderCompiler> = null;

	public static function setShaderCompiler(compiler:IShaderCompiler) {
		shaderCompiler = compiler;
	}

	public static var hasGlslC(get, never):Bool;
	@:persistent static var __hasGlslC:Null<Bool> = null;
	public static var hasSpirV(get, never):Bool;
	@:persistent static var __hasSpirV:Null<Bool> = null;

	static function get_hasGlslC():Bool {
		if (__hasGlslC != null)
			return __hasGlslC;
		__hasGlslC = cmd("glslc", ["--version"]).code == 0;
		return __hasGlslC;
	}

	static function get_hasSpirV():Bool {
		if (__hasSpirV != null)
			return __hasSpirV;
		__hasSpirV = cmd("spirv-cross", ["--help"]).code == 0;
		return __hasSpirV;
	}

	public static function getShaderCompiler():IShaderCompiler {
		if (Context.defined("display"))
			return new arcane.internal.empty.ShaderCompiler();
		if (shaderCompiler != null)
			return shaderCompiler;
		if (Context.defined("js"))
			// if (hasSpirV)
			return new arcane.internal.html5.HTML5ShaderCompiler();
		// else
		// return new arcane.internal.kinc.KrafixShaderCompiler();
		if (Context.defined("kinc") && Context.defined("hl"))
			return new arcane.internal.kinc.KrafixShaderCompiler();
		return new arcane.internal.empty.ShaderCompiler();
	}

	public static function getTempDir():String {
		// #if (haxe_ver >= 4.2)
		// return switch eval.luv.Path.tmpdir() {
		// 	case Ok(value): value.toString();
		// 	case Error(e): throw e;
		// }
		// #else
		var d = haxe.io.Path.directory(Compiler.getOutput());
		if (d == Sys.getCwd())
			return ".tmp";
		else
			return d + "/temp";
		// #end
	}

	public static function cmd(command:String, ?args:Array<String>, ?stdin:Bytes) {
		var p = new sys.io.Process(command, args);
		if (stdin != null) {
			p.stdin.write(stdin);
		}
		p.stdin.close();
		var stdout = p.stdout.readAll();
		var stderr = p.stderr.readAll();
		var code = p.exitCode();
		var ret = {
			stdout: stdout,
			stderr: stderr.toString(),
			code: code
		}
		p.close();
		return ret;
	}

	public static function initSourceMaps() {
		if (Context.defined("js")) {
			Context.onAfterGenerate(() -> {
				var o = Compiler.getOutput() + ".map";
				if (sys.FileSystem.exists(o)) {
					var json:{
						var version:Int;
						var file:String;
						var sourceRoot:String;
						var sources:Array<String>;
						var names:Array<Dynamic>;
						var mappings:String;
					} = haxe.Json.parse(File.getContent(o));
					File.saveContent(o, Json.stringify({
						version: json.version,
						file: json.file,
						sourceRoot: "",
						sources: json.sources.map(s -> json.sourceRoot + s),
						names: json.names,
						mappings: json.mappings,
					}));
				}
			});
		}
	}

	public static function findArcane():String {
		var file = switch Context.getType("arcane.Utils") {
			case TInst(t, _): t.get().pos.getInfos().file;
			case _: Context.fatalError("Could not find arcane.Utils, something is very very wrong.", Context.currentPos());
		}
		var p = Path.normalize(Path.join([Path.directory(file), "..", ".."]));
		return p;
	}
	#end
}
