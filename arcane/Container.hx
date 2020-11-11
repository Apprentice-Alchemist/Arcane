package arcane;

class Container extends h2d.Scene {
	public var state(default, set):IState;

	function set_state(s:IState):IState {
		return state;
	}
}
