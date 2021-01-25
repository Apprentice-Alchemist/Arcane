package arcane.common;

@:forward(dispatch, add, remove)
@:multiType
abstract Event<T>(IEvent<T>) {
	public function new();

	@:to static inline function toEvent0(e:IEvent<Void->Void>):Event0
		return new Event0();

	@:to static inline function toEvent1<K>(e:IEvent<K->Void>):Event1<K>
		return new Event1();

	@:to static inline function toEvent2<K1, K2>(e:IEvent<K1->K2->Void>):Event2<K1, K2>
		return new Event2();

	@:to static inline function toEvent3<K1, K2, K3>(e:IEvent<K1->K2->K3->Void>):Event3<K1, K2, K3>
		return new Event3();

	@:to static inline function toEvent4<K1, K2, K3, K4>(e:IEvent<K1->K2->K3->K4->Void>):Event4<K1, K2, K3, K4>
		return new Event4();

	@:to static inline function toEvent5<K1, K2, K3, K4, K5>(e:IEvent<K1->K2->K3->K4->K5->Void>):Event5<K1, K2, K3, K4, K5>
		return new Event5();

	@:to static inline function toEvent6<K1, K2, K3, K4, K5, K6>(e:IEvent<K1->K2->K3->K4->K5->K6->Void>):Event6<K1, K2, K3, K4, K5, K6>
		return new Event6();
}

private interface IEvent<T> {}

private class BaseEvent<T> {
	private var __dispatchers:Array<T> = [];

	public function new() {}

	public function add(cb:T):Void
		__dispatchers.push(cb);

	public function remove(cb:T):Void
		__dispatchers.remove(cb);
}

@:generic
class Event0 extends BaseEvent<Void->Void> {
	public function dispatch():Void
		for (cb in __dispatchers)
			cb();
}

@:generic
class Event1<T> extends BaseEvent<T->Void> {
	public function dispatch(v:T):Void
		for (cb in __dispatchers)
			cb(v);
}

@:generic
class Event2<T1, T2> extends BaseEvent<T1->T2->Void> {
	public function dispatch(v1:T1, v2:T2):Void
		for (cb in __dispatchers)
			cb((v1 : Dynamic), v2);
}

@:generic
class Event3<T1, T2, T3> extends BaseEvent<T1->T2->T3->Void> {
	public function dispatch(v1:T1, v2:T2, v3:T3):Void
		for (cb in __dispatchers)
			cb(v1, v2, v3);
}

@:generic
class Event4<T1, T2, T3, T4> extends BaseEvent<T1->T2->T3->T4->Void> {
	public function dispatch(v1:T1, v2:T2, v3:T3, v4:T4):Void
		for (cb in __dispatchers)
			cb(v1, v2, v3, v4);
}

@:generic
class Event5<T1, T2, T3, T4, T5> extends BaseEvent<T1->T2->T3->T4->T5->Void> {
	public function dispatch(v1:T1, v2:T2, v3:T3, v4:T4, v5:T5):Void
		for (cb in __dispatchers)
			cb(v1, v2, v3, v4, v5);
}

@:generic
class Event6<T1, T2, T3, T4, T5, T6> extends BaseEvent<T1->T2->T3->T4->T5->T6->Void> {
	public function dispatch(v1:T1, v2:T2, v3:T3, v4:T4, v5:T5, v6:T6):Void
		for (cb in __dispatchers)
			cb(v1, v2, v3, v4, v5, v6);
}
