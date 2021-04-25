package arcane.util;

#if !target.threaded
#error "ThreadPool only works on multithreaded targets"
#end
import sys.thread.Deque;
import sys.thread.Mutex;
import sys.thread.Thread;

@:nullSafety(StrictThreaded)
@:allow(arcane.util.ThreadPool)
private class Worker {
	var thread:Thread;
	var mutex:Mutex;
	var tasks:Deque<() -> (() -> Void)>;
	var completed_tasks:Deque<() -> Void>;

	public function new() {
		mutex = new Mutex();
		tasks = new Deque();
		completed_tasks = new Deque();
		thread = Thread.create(work);
	}

	function work() {
		while (true) {
			if (Thread.readMessage(false) != null)
				break;
			// mutex.acquire();
			var task = tasks.pop(true);
			// mutex.release();

			if (task != null) {
				var f = task();
				// mutex.acquire();
				completed_tasks.push(f);
				// mutex.release();
			}
			Sys.sleep(1 / 1000);
		}
	}
}

@:nullSafety(Strict)
class ThreadPool {
	private final threads:Array<Worker>;

	private final ml_ev:#if (haxe >= "4.2.0" && target.threaded) sys.thread.EventLoop.EventHandler #else haxe.MainLoop.MainEvent #end;
	private final owner_thread:Thread;

	public function new(count:Int = 4) {
		threads = [while (count-- > 0) new Worker()];
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
	 * @param execute
	 * @param complete
	 * @param err
	 */
	public function addTask<R>(execute:() -> R, complete:R->Void, ?err:haxe.Exception->Void):Void {
		final error:haxe.Exception->Void = err == null ? e -> trace("Unhandled exception in threadpool : " + e.message) : err;
		var t = threads[_ct >= threads.length ? --_ct : _ct++];
		t.mutex.acquire();
		t.tasks.push(() -> {
			var r = try execute() catch (e) return () -> error(e);
			return () -> complete(r);
		});
		t.mutex.release();
	}

	function process():Void {
		for (thread in threads) {
			// thread.mutex.acquire();
			var task = thread.completed_tasks.pop(false);
			while (task != null) {
				task();
				task = thread.completed_tasks.pop(false);
			}
			// thread.mutex.release();
		}
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
