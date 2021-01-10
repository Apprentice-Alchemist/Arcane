package arcane.common;

import arcane.signal.Signal;
import arcane.signal.SignalDispatcher;

// TODO : Figure out why I made this, and wether it should be removed
class Achievements extends SignalDispatcher {
	public static var newAchievement:SignalType<String> = "new_achievment";
	public static var instance:Null<Achievements>;

	public var map:Map<String, Bool> = new Map<String, Bool>();

	public function new() {
		instance = this;
		super();
	}

	public function clearAchievements() {
		map.clear();
		updateAchievements();
	}

	public function isAchievement(id:String):Bool {
		return true;
	}

	/**
	 * Call this this to give out an achievement, this will handle calling other functions.
	 * Will throw an exception of type string if isAchievement returns false for the given id.
	 * @param id
	 * @param silent
	 */
	public function gainAchievement(id:String, silent:Bool) {
		if(!isAchievement(id))
			throw '$id is not an achievement!';
		if(!map.exists(id) || !map.get(id)) {
			dispatch(new Signal("new_achievement", id));
			onAchievement(id, silent);
		}
		map.set(id, true);
		updateAchievements();
	}

	/**
	 * Called when an achievement is awarded, that had not previously been awarded.
	 * override this to provide custom behaviour such as new achievement popups.
	 * @param id
	 * @param silent
	 */
	public function onAchievement(id:String, silent:Bool) {}

	/**
	 * Called when achievements are updated, in gainAchievement and clearAchievements,
	 * override this to provide custom behaviour such as saving achievements somewhere.
	 */
	public function updateAchievements() {}
}
