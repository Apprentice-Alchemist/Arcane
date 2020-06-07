package arcane;

import haxe.Exception;
import arcane.xml.XmlPath;

class Lang {
	public static var cur_lang:String = "en_US";
	public static var langs:Map<String, Lang> = new Map();

	public static function loadLang(xml:XmlPath) {
		if (langs.exists(xml.get("id")))
			langs.get(xml.get("id")).addXml(xml);
		else
			langs.set(xml.get("id"), new Lang(xml));
	}

	public static function getText(id:String)
		return langs.exists(cur_lang) ? (langs.get(cur_lang).texts.exists(id) ? langs.get(cur_lang).texts.get(id) : "") : "";

	var texts:Map<String, String> = new Map();

	public function new(xml:XmlPath) {
		addXml(xml);
	}

	public function addXml(xml:XmlPath) {
		for (o in xml.elementsNamed("section")) {
			for (a in o.elementsNamed("text")) {
				texts.set(o.get("id") + "." + a.get("id"), a.firstChild().toString());
			}
		}
	}
}
