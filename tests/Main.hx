package;

import utest.ui.text.PlainTextReport;
import utest.Runner;

class Main {
	public static function main() {
		var runner = new Runner();
		runner.addCases(common);
		var report = new PlainTextReport(runner, report -> arcane.util.Log.println(report.getResults()));
		@:privateAccess {
			report.newline = "\n";
			report.indent = "    ";
		}
		runner.run();
	}
}
