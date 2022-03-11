package tools;

import sys.FileSystem;
import haxe.io.Path;
import arcane.util.Log.*;
import arcane.util.Log;

using Lambda;
using StringTools;

interface ICommand {
	public var doc:Doc;
	public function run(args:Array<String>, switches:Map<String, String>):Void;
}

typedef Doc = {
	var args:Array<{
		var optional:Bool;
		var id:String;
		var doc:String;
	}>;
	var switches:Map<String, {
		var doc:String;
		var aliases:Array<String>;
		var ?has_value:Bool;
	}>;
	var doc:String;
}

@:structInit
@:publicFields
private class GlobalSwitch {
	var doc:String;
	var aliases:Array<String>;
	var has_value:Bool = false;
	var values:Array<String>;
	var action:String->Void;

	public function new(doc:String, aliases:Array<String>, action:String->Void, has_value:Bool = false) {
		this.doc = doc;
		this.aliases = aliases;
		this.action = action;
		this.has_value = has_value;
	}
}

enum Pair<K, V> {
	KeyOnly(k:K);
	KeyValue(k:K, v:V);
}

class Main {
	public static var commands:Map<String, ICommand> = ["help" => new HelpCommand(), "create" => new CreateCommand()];
	public static var global_switches:Array<GlobalSwitch> = [
		{
			doc: "Turn on verbose mode",
			aliases: ["-v", "--verbose"],
			action: _ -> Log.VERBOSE = true
		},
		{
			doc: "Disable warning messages",
			aliases: ["-wd", "--disable-warnings"],
			action: _ -> Log.WARN = false
		}
	];
	public static var libdir:String = Sys.getCwd();

	public static function main():Void {
		Log.LOG_POSITION = false;
		var args = Sys.args();
		Sys.setCwd(args.pop());

		var switches:Map<String, String> = new Map();
		var cargs = [];
		var command = if (args.length > 0) args.shift() else "help";
		for (a in args) {
			if (a.startsWith("-")) {
				var i = a.indexOf("=");
				if (i == -1)
					i = a.length;
				var s = a.substring(0, i);
				var v = a.substring(i, a.length);
				for (gs in global_switches)
					if (gs.aliases.indexOf(s) > -1) {
						gs.action(v);
						break;
					} else {
						switches.set(s, v);
					}
			} else {
				cargs.push(a);
			}
		}

		if (!commands.exists(command)) {
			Log.error("Unknown command '" + command + "'");
			Log.println("Run 'arcane help' to see a list of all commands.");
		} else {
			var cmd = commands.get(command);
			var doc = cmd.doc;
			if (cargs.length > doc.args.length) {
				Log.error('Too many arguments for command \'$command\'.\n'
					+ 'Run \'arcane help $command\' for more information on how to use this command.');
				return;
			}
			var needed_args = 0;
			for (i in doc.args)
				if (!i.optional)
					needed_args++;

			if (cargs.length < needed_args) {
				Log.error('Not enough arguments for command \'$command\'.\n'
					+ 'Run \'arcane help $command\' for more information on how to use this command.');
				return;
			}
			final real_switches = new Map<String, String>();
			for (s => v in switches) {
				for (dname => ds in doc.switches) {
					if (ds.aliases.contains(s)) {
						real_switches.set(dname, v);
						continue;
					}
					Log.warn("Unknown switch '" + s + "'");
				}
			}
			cmd.run(cargs, real_switches);
		}
	}

	public static function logo() {
		println("     _                             ");
		println("    / \\   _ __ ___ __ _ _ __   ___ ");
		println("   / _ \\ | '__/ __/ _` | '_ \\ / _ \\");
		println("  / ___ \\| | | (_| (_| | | | |  __/");
		println(" /_/   \\_\\_|  \\___\\__,_|_| |_|\\___|");
		println('Arcane ${arcane.Lib.version}');
	}
}

class HelpCommand implements ICommand {
	public function new() {}

	public var doc:Doc = {
		args: [
			{
				id: "command",
				optional: true,
				doc: "Show extended help about a specific command."
			}
		],
		switches: [],
		doc: "Show help about these tools, or about a specific command."
	};

	public function run(args:Array<String>, switches:Map<String, Null<String>>) {
		if (args.length == 0) {
			Main.logo();
			generalHelp();
		} else
			commandHelp(args[0]);
	}

	public function commandHelp(id:String) {
		if (@:privateAccess !Main.commands.exists(id)) {
			Log.error("Unkown command '" + id + "'");
			Log.println("Run 'arcane help' to see a list of all commands.");
			return;
		}
		var doc = @:privateAccess Main.commands.get(id).doc;
		var buf = new LineBuf();
		buf.add("- " + doc.doc + "\n");
		buf.add("Usage : arcane " + id + " " + doc.args.map(a -> a.optional ? ("(" + a.id + ")") : ("<" + a.id + ">")).join(" "));
		buf.add("\n\n");

		if (doc.switches.count() > 0) {
			buf.add("Switches :\n");
			buf.indent(() -> {
				for (value in doc.switches) {
					var str = value.aliases.join(", ");
					if (value.has_value)
						str += "=<value>";
					var length = 30 - str.length;
					str += [for (_ in 0...length) " "].join("");
					str += "- " + value.doc + "\n";
					buf.add(str);
				}
			});
		}
		println(buf.dump());
	}

	public function generalHelp() {
		var buf = new LineBuf();
		buf.add("Commands : \n");
		buf.indent(() -> {
			for (key => value in @:privateAccess Main.commands) {
				var doc = value.doc;
				var length = 30 - '$key '.length;
				buf.add('$key ' + [for (_ in 0...length) " "].join("") + "-  " + doc.doc + "\n");
			}
		});
		buf.add("\n");
		buf.add("Global Switches : \n");
		buf.indent(() -> {
			for (key => value in @:privateAccess Main.global_switches)
				@:privateAccess {
				var str = value.aliases.join(", ");
				if (value.has_value)
					str += "=<value>";
				var length = 30 - str.length;
				str += [for (_ in 0...length) " "].join("");
				str += "- " + value.doc + "\n";
				buf.add(str);
			}
		});
		println(buf.dump());
	};
}

class CreateCommand implements ICommand {
	public function new() {}

	public var doc:Doc = {
		args: [
			{
				id: "template",
				optional: true,
				doc: "Which template to use"
			},
			{
				id: "path",
				optional: true,
				doc: "Where to create the project, defaults to the current working directory"
			}
		],
		switches: [
			"list" => {
				doc: "List available templates",
				aliases: ["-l", "--list"]
			}
		],
		doc: "Create a new Arcane project from a template."
	};

	public function run(args:Array<String>, switches:Map<String, Null<String>>) {
		if (switches.exists("list")) {
			final templates_path = Path.normalize(Path.join([Main.libdir, "templates"]));
			if (FileSystem.exists(templates_path)) {
				final templates = FileSystem.readDirectory(templates_path);
				println("Available templates :");
				for (template in templates) {
					println('	$template');
				}
			} else {
				println("No templates found.");
			}
		} else {
			final template = args.length > 0 ? args.pop() : "default";
			final path = args.length > 0 ? {
				final p = args.pop();
				if (Path.isAbsolute(p))
					p
				else
					Path.normalize(Path.join([Sys.getCwd(), p]));
			} : Sys.getCwd();

			final template_path = Path.normalize(Path.join([Main.libdir, "templates", template]));
			if (FileSystem.exists(template_path)) {
				FileSystemUtils.copyDirectory(template_path, path);
			} else {
				Log.error('No template found with id \'$template\'.');
				Log.error('Run \'arcane create --list\' to list available templates.');
			}
		}
	}
}

class ServerCommand implements ICommand {
	public var doc:Doc = null;

	public function run(args:Array<String>, switches:Map<String, Null<String>>) {}

	public function new() {}
}

class LineBuf {
	var buf:StringBuf;
	var indt = "";

	public inline function new() buf = new StringBuf();

	public inline function add(s:String) buf.add(indt + s);

	public inline function indent(f:Void->Void) {
		var old = indt;
		indt = (old + "   ");
		f();
		indt = old;
	}

	public inline function dump() return buf.toString();
}
