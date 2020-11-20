package arcane.util;

#if !target.threaded
#error "ThreadPool only works on multithreaded targets"
#end
import sys.thread.*;

private enum ThreadStatus {
	Awake;
	Sleeping;
}

@:nullSafety(StrictThreaded)
private class Task {
	public var in_data:Null<Dynamic>;
	public var out_data:Null<Dynamic>;
	public var error_data:Null<Dynamic>;
	public var is_errored:Bool;
	public var is_executed:Bool;
	public var on_execute:Task->Void;
	public var on_complete:Task->Void;
	public var on_error:Task->Void;

	public function new(_in, exec, comp, err) {
		in_data = _in;
		out_data = null;
		error_data = null;
		is_errored = false;
		is_executed = false;
		on_execute = exec;
		on_complete = comp;
		on_error = err;
	}

	public function execute() {
		try {
			on_execute(this);
		} catch (e) {
			error_data = e;
			is_errored = true;
		}
		is_executed = true;
	}

	public function complete() {
		Utils.assert(is_executed);
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
	public var tasks:Array<Task>;
	public var completed_tasks:Array<Task>;
	public var status:ThreadStatus = Sleeping;

	public function new() {
		mutex = new Mutex();
		tasks = [];
		completed_tasks = [];
		thread = Thread.create(work);
	}

	function work() {
		Sys.sleep(0.1);
		var sleeping = true;
		while (true) {
			var _msg = Thread.readMessage(false);
			if (_msg == "wake") {
				sleeping = false;
			}
			if (_msg == "die")
				break;
			if (!sleeping) {
				// mutex.acquire();
				status = Awake;
				var t = tasks.pop();
				// mutex.release();
				while (t != null) {
					t.execute();
					// mutex.acquire();
					completed_tasks.push(t);
					t = tasks.pop();
					// mutex.release();
				}
				// mutex.acquire();
				status = Sleeping;
				// mutex.release();
				sleeping = true;
			}
			// Sys.sleep(0.1);
		}
	}
}

/**
 * A pool of threads for tasks that should be executed asynchronusly
 */
@:nullSafety(StrictThreaded)
class ThreadPool {
	public static var threads:Array<ThreadData> = [];

	public static function __init__() {
		threads = [for(_ in 0...4) new ThreadData()];
		haxe.MainLoop.add(process);
	}

	private static var _ct:Int = 0;

	public static function addTask(_in, exec, comp, err, wake_thread = true) {
		var id = _ct >= threads.length ? (_ct = 0) : _ct++;
		var t = threads[id];
		// t.mutex.acquire();
		t.tasks.push(new Task(_in, exec, comp, err));
		// t.mutex.release();
		if (wake_thread)
			t.thread.sendMessage("wake");
	}

	public static function process() {
		for (thread in threads) {
			// if (thread.mutex.tryAcquire()) {
				var task = thread.completed_tasks.pop();
				while (task != null) {
					task.complete();
					task = thread.completed_tasks.pop();
				}
			// 	thread.mutex.release();
			// }
		}
	}

	public static function awaken() {
		for (thread in threads) {
			thread.thread.sendMessage("wake");
		}
	}
}
