package tools;

using StringTools;
using Lambda;

interface ICommand {
	public function doc():Doc;
	public function run(args:Array<String>, switches:Map<String, String>):Void;
}

typedef Doc = {
	var args:Array<{
		var optional:Bool;
		var id:String;
		var doc:String;
		var ?options:Map<String, String>;
	}>;
	var switches:Map<String, {
		var doc:String;
		var aliases:Array<String>;
		var ?has_value:Bool;
		var ?values:Array<String>;
	}>;
	var doc:String;
}

@:structInit
private class GlobalSwitch {
	var doc:String;
	var aliases:Array<String>;
	var has_value:Bool = false;
	var values:Array<String>;
	var action:(?String) -> Void;

	public function new(doc:String, aliases:Array<String>, action:?String->Void, has_value:Bool = false) {
		this.doc = doc;
		this.aliases = aliases;
		this.action = function(?s) {
			executed = true;
			action(s);
		};
		this.has_value = has_value;
	}

	var executed:Bool = false;

	public function match(s:Pair<String, String>) {
		switch s {
			case KeyOnly(k):
				if(aliases.contains(k)) {
					if(!executed)
						action();
					return true;
				}
			case KeyValue(k, v):
				if(has_value)
					if(aliases.contains(k)) {
						if(!executed)
							action();
						return true;
					}
		}

		return false;
	}
}

enum Pair<K, V> {
	KeyOnly(k:K);
	KeyValue(k:K, v:V);
}

class Main {
	static final commands:Map<String, ICommand> = ["help" => new HelpCommand(), "create" => new CreateCommand()];
	static final global_switches:Map<String, GlobalSwitch> = [
		"verbose" => {
			doc: "Turn on verbose mode",
			aliases: ["-v", "--verbose"],
			action: (?s) -> Log.is_verbose = true
		},
		"no_warning" => {
			doc: "Disable warning messages",
			aliases: ["-wd", "--disable-warnings"],
			action: (?s) -> Log.warning_disabled = true
		}
	];

	public static var cwd:String;

	public static function main() {
		var args = Sys.args();
		cwd = args.pop();
		var switches:Array<Pair<String, String>> = [];
		var command:String = null;
		var c_args:Array<String> = [];
		while (true) {
			var arg = args.shift();
			if(arg == null)
				break;
			if(arg.startsWith("-")) {
				if(arg.contains("="))
					switches.push(KeyValue(arg.split("=")[0], arg.split("=")[1]))
				else
					switches.push(KeyOnly(arg));
			} else if(command == null)
				command = arg;
			else
				c_args.push(arg);
		}
		var to_remove = [];
		for (s in switches)
			for (x in global_switches.iterator())
				if(x.match(s))
					to_remove.push(s);
		for (x in to_remove)
			switches.remove(x);
		if(command == null)
			commands.get("help").run([], []);
		else if(!commands.exists(command)) {
			Log.error("Unknown command '" + command + "'");
			Log.println("Run 'arcane help' to see a list of all commands.");
		} else {
			var cmd = commands.get(command);
			var doc = cmd.doc();
			var cmd_switches:Map<String, String> = [];
			if(c_args.length > doc.args.length) {
				Log.error('Too many arguments for command \'$command\'.\n' + 'Run \'arcane help $command\' for more information on how to use this command.');
				return;
			}
			var needed_args = 0;
			for (i in doc.args)
				if(!i.optional)
					needed_args++;

			if(c_args.length < needed_args) {
				Log.error('Not enough arguments for command \'$command\'.\n'
					+ 'Run \'arcane help $command\' for more information on how to use this command.');
			}

			for (id => sw in doc.switches) {
				for (i in switches)
					switch i {
						case KeyOnly(k):
							if(sw.aliases.contains(k))
								cmd_switches.set(id, null);
							else {
								Log.warning('Unknown switch \'$k\', ignoring.');
							}

						case KeyValue(k, v):
							if(sw.aliases.contains(k))
								cmd_switches.set(id, v);
							else {
								Log.warning('Unknown switch \'$k\', ignoring.');
							}
					}
			}
			cmd.run(c_args, cmd_switches);
		}
	}

	public static function logo() {
		Sys.println("     _                             
    / \\   _ __ ___ __ _ _ __   ___ 
   / _ \\ | '__/ __/ _` | '_ \\ / _ \\
  / ___ \\| | | (_| (_| | | | |  __/
 /_/   \\_\\_|  \\___\\__,_|_| |_|\\___|");
		Sys.println('Arcane Version : ${arcane.Lib.version}');
	}
}

class HelpCommand implements ICommand {
	public function new() {}

	public function doc():Doc
		return {
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
		if(args.length == 0) {
			Main.logo();
			generalHelp();
		} else
			commandHelp(args[0]);
	}

	public function commandHelp(id:String) {
		if(@:privateAccess !Main.commands.exists(id)) {
			Log.error("Unkown command '" + id + "'");
			Log.println("Run 'arcane help' to see a list of all commands.");
			return;
		}
		var doc = @:privateAccess Main.commands.get(id).doc();
		var buf = new LineBuf();
		buf.add("- " + doc.doc + "\n");
		buf.add("Usage : arcane " + id + " " + [for (a in doc.args) a.optional ? ("(" + a.id + ")") : ("<" + a.id + ">")].join(" "));
		buf.add("\n\n");

		if(doc.switches.count() > 0) {
			buf.add("Switches :\n");
			buf.indent(function() {
				for (value in doc.switches) {
					var str = value.aliases.join(", ");
					if(value.has_value)
						str += "=<value>";
					var length = 30 - str.length;
					str += [for (_ in 0...length) " "].join("");
					str += "- " + value.doc + "\n";
					buf.add(str);
				}
			});
		}
		Sys.println(buf.dump());
	}

	public function generalHelp() {
		var buf = new LineBuf();
		buf.add("Commands : \n");
		buf.indent(function() {
			for (key => value in @:privateAccess Main.commands) {
				var doc = value.doc();
				var length = 30 - '$key '.length;
				buf.add('$key ' + [for (_ in 0...length) " "].join("") + "-  " + doc.doc + "\n");
			}
		});
		buf.add("\n");
		buf.add("Global Switches : \n");
		buf.indent(function() {
			for (key => value in @:privateAccess Main.global_switches)
				@:privateAccess {
				var str = value.aliases.join(", ");
				if(value.has_value)
					str += "=<value>";
				var length = 30 - str.length;
				str += [for (_ in 0...length) " "].join("");
				str += "- " + value.doc + "\n";
				buf.add(str);
			}
		});
		Sys.println(buf.dump());
	};
}

class CreateCommand implements ICommand {
	public function new() {}

	public function doc():Doc
		return {
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
		Sys.println("Not implemented yet.");
	}
}

class LineBuf {
	var buf:StringBuf;
	var indt = "";

	public function new() buf = new StringBuf();

	public function add(s:String) buf.add(indt + s);

	public function indent(f:Void->Void) {
		var old = indt;
		indt = (old + "   ");
		f();
		indt = old;
	}

	public function dump() return buf.toString();
}
