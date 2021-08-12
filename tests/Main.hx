package;

import arcane.util.Log;
import utest.ui.common.PackageResult;
import utest.ui.text.PlainTextReport;
import utest.Runner;

private class Report extends PlainTextReport {
	public function new(runner) {
		this.newline = "\n";
		this.indent = "    ";
		super(runner);
	}

	override function complete(result:PackageResult) {
		this.result = result;
		Log.println(getResults());
		#if eval
		if (!result.stats.isOk)
			Sys.exit(1);
		#elseif sys
		Sys.exit(results.stats.isOK ? 0 : 1);
		#end
	}
}

class Main {
	public static function main() {
		var runner = new Runner();
		runner.addCases(common);
		var report = new Report(runner);
		runner.run();
	}
}
