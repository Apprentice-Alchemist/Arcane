package arcane.util;

#if !target.threaded
#error "arcane.util.ThreadPool is only available on multithreaded targets"
#end
import sys.thread.Deque;
import sys.thread.Thread;

@:nullSafety(StrictThreaded)
private class Worker {
	public final thread:Thread;
	public final tasks:Deque<() -> (() -> Void)>;
	public final completed_tasks:Deque<() -> Void>;

	public function new() {
		tasks = new Deque();
		completed_tasks = new Deque();
		thread = Thread.create(work);
	}

	function work() {
		while (true) {
			if (Thread.readMessage(false) != null)
				break;
			var task = tasks.pop(true);
			if (task != null) {
				var f = task();
				completed_tasks.push(f);
			}
			Sys.sleep(1 / 1000);
		}
	}
}

@:nullSafety(StrictThreaded)
class ThreadPool {
	final threads:Array<Worker>;

	final ml_ev:#if (haxe >= "4.2.0" && target.threaded) sys.thread.EventLoop.EventHandler #else haxe.MainLoop.MainEvent #end;
	final owner_thread:Thread;

	/**
	 * Create a new thread pool
	 * @param count amout of threads to use in the pool
	 */
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

	var _ct:Int = 0;

	/**
	 * Add a task to be executed on another thread.
	 * @param execute Callback that will be called on another thread.
	 * @param complete Callback that will be executed on the main thread.
	 * @param err Optional function to handle exceptions.
	 */
	public function addTask<R>(execute:() -> R, complete:R->Void, ?err:haxe.Exception->Void):Void {
		final error:haxe.Exception->Void = err == null ? e -> Log.error("Unhandled exception in threadpool : " + e.message) : err;
		final thread = threads[_ct >= threads.length ? _ct = 0 : _ct++];
		thread.tasks.push(() -> {
			var r = try execute() catch (e) return () -> error(e);
			return () -> complete(r);
		});
	}

	function process():Void {
		for (thread in threads) {
			var task = thread.completed_tasks.pop(false);
			while (task != null) {
				task();
				task = thread.completed_tasks.pop(false);
			}
		}
	}

	/**
	 * Disposes of all threads. Tasks still queued might or might not be executed.
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
