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

	// public inline function send(m:ThreadMessage) {
	// 	this.thread.sendMessage(m);
	// }

	function work() {
		while (true) {
			if (Thread.readMessage(false) != null)
				break;
			mutex.acquire();
			var task = tasks.pop(false);
			mutex.release();

			if (task != null) {
				task.execute();
				mutex.acquire();
				completed_tasks.push(task);
				mutex.release();
				Sys.sleep(1 / 1000);
			} else {
				Sys.sleep(1 / 1000);
			}
		}
	}
}

@:nullSafety(Strict)
class ThreadPool {
	private final threads:Array<ThreadData>;

	private final ml_ev:#if (haxe >= "4.2.0" && target.threaded) sys.thread.EventLoop.EventHandler #else haxe.MainLoop.MainEvent #end;
	private final owner_thread:Thread;

	public function new(count:Int = 4) {
		threads = [while (count-- > 0) new ThreadData()];
		owner_thread = Thread.current();
		#if (haxe >= "4.2.0" && target.threaded)
		ml_ev = owner_thread.events.repeat(process, 5);
		#else
		ml_ev = haxe.MainLoop.add(process);
		ml_ev.isBlocking = false;
		#end
	}

	private var _ct:Int = 0;

	/**
	 * Add a task to be executed on another thread.
	 */
	public function addTask(_in:Null<Dynamic>, execute:Task->Void, complete:Task->Void, error:Task->Void, wake_thread:Bool = true):Void {
		var t = threads[_ct >= threads.length ? (_ct = 0) : _ct++];
		t.mutex.acquire();
		t.tasks.push(new Task(_in, execute, complete, error));
		t.mutex.release();
		// if (wake_thread)
		// 	t.thread.sendMessage((Wake : ThreadMessage));
	}

	function process():Void {
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
		// for (thread in threads) {
		// 	thread.send(Wake);
		// }
	}

	/**
	 * Disposes of all threads. Tasks still queued might or might now be executed.
	 * The pool should not be used after this.
	 */
	public function dispose():Void {
		while (threads.length > 0)
			@:nullSafety(Off) threads.pop().thread.sendMessage(1);
		#if (haxe >= "4.2.0" && target.threaded)
		owner_thread.events.cancel(ml_ev);
		#else
		ml_ev.stop();
		#end
	}
}
