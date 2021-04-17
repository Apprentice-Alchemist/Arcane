package;

import utest.ui.text.PlainTextReport;
import utest.Runner;

class Main {
	public static function main() try {
		var runner = new Runner();
		runner.addCases(common);
		var report = new PlainTextReport(runner, report -> {
			arcane.util.Log.println(report.getResults());
			throw new ExitException();
		});
		@:privateAccess {
			report.newline = "\n";
			report.indent = "    ";
		}
		runner.run();
	} catch(e:ExitException) {};
}

#if (haxe_ver > "4.1.0")
class ExitException extends haxe.Exception {
	override public function new() {
		super("");
	}
}
#else
class ExitException {
	public function new(){}
}
#end