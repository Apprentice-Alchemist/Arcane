package arcane.common;

import arcane.signal.SignalDispatcher;

class Achievements {
	public static final achievements = new Map<String, Achievement>();

	public static function loadAchievement(a:Achievement)
		achievements.set(a.name, a);

	public static function awardAchievement(name:String):Bool {
		if (!achievements.exists(name))
			return false;
		var a = achievements.get(name);
		if (a.awarded == true)
			return false;
		a.awarded = true;
		onAchievement(achievements.get(name));
		return true;
	}

	public static dynamic function onAchievement(a:Achievement) {}
}

class Achievement {
	public var name:String = "";
	public var awarded:Bool = false;
	public var extraInfo:Any;
	public function new(name:String,?extraInfo:Any){this.extraInfo = extraInfo; this.name = name;}

	public function toString()
		return Lang.getText('achievements.names',name);
}
