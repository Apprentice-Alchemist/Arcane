package arcane;

class Lang {
	static var cur_lang:String = "en_US";
	static var langs:Map<String, Lang> = new Map();

	public static function loadText(lang:String, section:String, id:String, value:String):Void
		getLang(lang).getSection(section).texts.set(id, value);

	public static function getText(section:String, id:String):String
		return getLang(cur_lang).getSection(section).texts.get(id);

	public static function setLang(id:String)
		cur_lang = getLang(id).id;

	var sections = new Map<String, Section>();
	var id:String;

	public function new(id:String):Void
		this.id = id;

	inline function getSection(id):Section {
		if (!sections.exists(id))
			sections.set(id, new Section());
		return sections.get(id);
	}

	static inline function getLang(id:String):Lang {
		if (!langs.exists(id))
			langs.set(id, new Lang(id));
		return langs.get(id);
	}
}

@:allow(Lang)
@:noCompletion class Section {
	public var texts = new Map<String, String>();

	public function new()
		return;
}
