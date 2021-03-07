package arcane.util;

#if !target.threaded
#error "ThreadPool only works on multithreaded targets"
#end

import sys.thread.Deque;
import sys.thread.Mutex;
import sys.thread.Thread;

private enum ThreadStatus {
	Awake;
	Sleeping;
}

private enum ThreadMessage {
	Wake;
	Die;
}

@:nullSafety(StrictThreaded)
private class Task {
	public var in_data:Null<Dynamic>;
	public var out_data:Null<Dynamic>;
	public var error_data(default, set):Null<Dynamic>;
	public var is_errored:Bool;
	public var is_executed:Bool;
	public var on_execute:Task->Void;
	public var on_complete:Task->Void;
	public var on_error:Task->Void;

	public function new(_in, exec, comp, err) {
		in_data = _in;
		out_data = null;
		is_errored = false;
		error_data = null;
		is_executed = false;
		on_execute = exec;
		on_complete = comp;
		on_error = err;
	}

	private inline function set_error_data(d) {
		error_data = d;
		if (d != null)
			is_errored = true;
		return d;
	}

	public function execute() {
		try {
			on_execute(this);
		} catch (e) {
			error_data = e;
		}
		is_executed = true;
	}

	public function complete() {
		if (is_errored)
			on_error(this);
		else
			on_complete(this);
	}
}

@:nullSafety(StrictThreaded)
private class ThreadData {
	public var thread:Thread;
	public var mutex:Mutex;
	public var tasks:Deque<Task>;
	public var completed_tasks:Deque<Task>;

	public function new() {
		mutex = new Mutex();
		tasks = new Deque();
		completed_tasks = new Deque();
		thread = Thread.create(work);
	}

	public inline function send(m:ThreadMessage) {
		this.thread.sendMessage(m);
	}

	function work() {
		var sleeping = true;
		while (true) {
			var _msg:Null<ThreadMessage> = Thread.readMessage(false);
			switch _msg {
				case Wake:
					sleeping = false;
				case Die:
					break;
				case _:
			}
			if (!sleeping) {
				mutex.acquire();
				var t:Array<Task> = [];
				var val = tasks.pop(false);
				while (val != null) {
					t.push(val);
					val = tasks.pop(false);
				}
				mutex.release();

				for (i in t) {
					i.execute();
				}

				mutex.acquire();
				for (i in t) {
					completed_tasks.push(i);
				}
				sleeping = true;
				mutex.release();
			}
			Sys.sleep(0.1);
		}
	}
}

@:nullSafety(Strict)
class ThreadPool {
	public var threads:Array<ThreadData> = [];

	private var ml_ev:Null<haxe.MainLoop.MainEvent>;

	private function create():Void {
		if (threads.length > 0)
			return;
		threads = [for (_ in 0...4) new ThreadData()];
		ml_ev = haxe.MainLoop.add(process);
		ml_ev.isBlocking = false;
	}

	public function new() {
		create();
	}

	private var _ct:Int = 0;

	public function addTask(_in, exec, comp, err, wake_thread = true):Void {
		create();
		var id = _ct >= threads.length ? (_ct = 0) : _ct++;
		var t = threads[id];
		t.mutex.acquire();
		t.tasks.push(new Task(_in, exec, comp, err));
		t.mutex.release();
		if (wake_thread)
			t.thread.sendMessage((Wake : ThreadMessage));
	}

	public function process():Void {
		for (thread in threads) {
			thread.mutex.acquire();
			var task = thread.completed_tasks.pop(false);
			while (task != null) {
				task.complete();
				task = thread.completed_tasks.pop(false);
			}
			thread.mutex.release();
		}
	}

	public function awaken():Void {
		create();
		for (thread in threads) {
			thread.send(Wake);
		}
	}

	public function dispose():Void {
		for (thread in threads) {
			thread.send(Die);
		}
		threads = [];
		if (ml_ev != null)
			ml_ev.stop();
		ml_ev = null;
	}
}
