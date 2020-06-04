package arcane.adv;

import arcane.xml.XmlPath;

class ModHandler {
	public static var core_path:String = "core/mod.xml";
	// public static var mods_path:String = "assets/mods/";
	// public static var mod_file:String = "mod.xml";
	public static var action_map:Map<String, XmlPath -> Void> = null;

	public static function loadData(?onComplete:Void->Void) {
		loadActionMap();
		var files = [core_path];
		for (o in files) {
			var p = new haxe.io.Path(o);
			parseXml(new XmlPath(p.dir == null ? "" : p.dir, Xml.parse(hxd.Res.load(o).toText()).firstElement()));
		}
		if (onComplete != null)
			onComplete();
	}

	public static var extraActions:Map<String, XmlPath->Void>->Void;

	public static function loadActionMap() {
		if (action_map == null) {
			action_map = new Map<String, XmlPath->Void>();
		}
		action_map.clear();
		action_map.set("include", function(o:XmlPath) {
			if (o.get("id") != null) {
				var p = new haxe.io.Path(o.path + "/" + o.get("id"));
				trace(p.toString());
				parseXml(new XmlPath(p.dir, Xml.parse(hxd.Res.load(p.dir + "/" + p.file + "." + p.ext).toText()).firstElement()));
			}
		});
		if (extraActions != null)
			extraActions(action_map);
	}

	public static function parseXml(s:XmlPath) {
		for (o in s.elements()) {
			if (action_map.exists(o.nodeName)) {
                trace(o.nodeName);
				action_map.get(o.nodeName)(makeXml(o, s.path));
			}
		}
	}

	public static function makeXml(xml:Xml, path:String) {
		return new XmlPath(path, xml);
	}
}
