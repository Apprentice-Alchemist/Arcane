package;

import utest.ui.text.PlainTextReport;
import utest.Runner;

class Main {
	public static function main() try {
		var runner = new Runner();
		runner.addCases(common);
		var report = new PlainTextReport(runner, report -> {
			arcane.util.Log.println(report.getResults());
			// prevent utest from calling Sys.exit(0) because all calls to Sys.exit
			// make the compiler exit with non zero exit code, thus making the CI fail
			throw new ExitException(@:privateAccess report.result.stats.isOk);
		});
		@:privateAccess {
			report.newline = "\n";
			report.indent = "    ";
		}
		runner.run();
	} catch(e:ExitException) {if(!e.success) Sys.exit(1);};
}

#if (haxe_ver > "4.1.0")
class ExitException extends haxe.Exception {
	public final success:Bool;
	override public function new(success:Bool) {
		super("");
		this.success = success;
	}
}
#else
class ExitException {
	public final success:Bool;
	public function new(success:Bool){
		this.success = success;
	}
}
#end