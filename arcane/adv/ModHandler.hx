package arcane.adv;

import haxe.Exception;
import arcane.common.Achievements;
import arcane.xml.XmlPath;

class ModHandler {
	public static var core_path:String = "core/mod.xml";
	// public static var mods_path:String = "assets/mods/";
	// public static var mod_file:String = "mod.xml";
	public static var action_map:Map<String, XmlPath->Void> = new Map();

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
		action_map.clear();
		action_map.set("include", function(o:XmlPath) {
			if (o.get("id") != null) {
				var p = new haxe.io.Path(o.path + "/" + o.get("id"));
				try{
					parseXml(new XmlPath(p.dir, Xml.parse(hxd.Res.load(p.dir + "/" + p.file + "." + p.ext).toText()).firstElement()));
				}catch(e){
					trace("File not found : " + (p.dir + "/" + p.file + "." + p.ext));
				}
			}
		});
		action_map.set("lang", function(o:XmlPath) {
			var l = o.get("id");
			for (s in o.elementsNamed("section")) {
				for (t in s.elementsNamed("text")) {
					arcane.Lang.loadText(l, s.get("id"), t.get("id"), t.firstChild().toString());
				}
			}
		});
		action_map.set("achievement",function(o:XmlPath) {
			Achievements.loadAchievement(new Achievement(o.get("id"),o));
		});
		if (extraActions != null)
			extraActions(action_map);
	}

	public static function parseXml(s:XmlPath) {
		for (o in s.elements()) {
			if (action_map.exists(o.nodeName)) {
				try{
				action_map.get(o.nodeName)(makeXml(o, s.path));
				}
				catch(e){
					trace(e.details());
				}
			}
		}
	}

	public static function makeXml(xml:Xml, path:String) {
		return new XmlPath(path, xml);
	}
}
