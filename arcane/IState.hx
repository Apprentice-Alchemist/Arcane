package arcane;

interface IState {
	/**
	 * Called when the IState is added to the scene
	 */
	public function create():Void;

	/**
	 * Obvious. Isn't it?
	 * @param dt
	 */
	public function update(dt:Float):Void;

	/**
	 * Called when the scene is resized.
	 */
	public function onResize():Void;

	/**
	 * Called when the IState is removed from the scene
	 */
	public function destroy():Void;

	/**
	 * Called after `destroy` if the state is to be disposed
	 */
	public function dispose():Void;
}
