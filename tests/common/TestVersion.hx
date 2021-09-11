package common;

import arcane.util.Version;

class TestVersion extends utest.Test {
	function testVersion() {
		assert(new Version("4.3.0") > new Version("4.2.0"));
		assert(new Version("4.2.0") < new Version("4.3.0"));
		assert(new Version("4.3.0") >= new Version("4.2.0"));
		assert(new Version("4.2.0") <= new Version("4.3.0"));
		assert(new Version("4.2.0") == new Version("4.2.0"));

		var v = new Version("4.2.0-rc3+gitcommithash");
		assert(v.major == 4);
		assert(v.minor == 2);
		assert(v.patch == 0);
		assert(v.other == "rc3");
		assert(v.build == "gitcommithash");
	}
}
