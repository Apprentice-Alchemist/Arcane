package arcane.util;

#if !target.threaded
#error "ThreadPool only works on multithreaded targets"
#end
import sys.thread.*;

using arcane.util.ThreadUtil;

private typedef ThreadTask = {
	var in_data:Dynamic;
	var out_data:Dynamic;
	var execute:ThreadTask->Void;
	var complete:ThreadTask->Void;
	@:optional var error:Bool;
}

/**
 * A pool of threads for tasks that should be executed asynchronusly
 */
class ThreadPool {
	public static inline var DEFAULT_THREAD_COUNT = 4;

	var task_mutex:Mutex;
	var thread_pool:Array<Thread>;
	var tasks:Deque<ThreadTask>;
	var completed_tasks:Deque<ThreadTask>;

	/**
	 * @param thread_count the amount of threads to create, defaults to 4
	 */
	public function new(thread_count:Int = DEFAULT_THREAD_COUNT):Void {
		task_mutex = new Mutex();
		thread_pool = [];
		tasks = new Deque();
		completed_tasks = new Deque();
		for (_ in 0...thread_count) {
			thread_pool.push(Thread.create(work));
		}
	}
	
	function work():Void {
		while (true) {
			if (Thread.readMessage(false) == "die") break;
			task_mutex.acquire();
			var task = tasks.pop(false);
			task_mutex.release();
			if (task != null) {
				try {
					task_mutex.acquire();
					task.execute(task);
					task_mutex.release();
				} catch (e) {
					task.error = true;
					trace("Exception occured while handling a task!");
					trace(e.message);
				}
				task_mutex.acquire();
				completed_tasks.push(task);
				task_mutex.release();
			}
			Sys.sleep(0.01);
		}
	}

	public function process():Void {
		task_mutex.acquire();
		var _tasks = completed_tasks.megaPop();
		task_mutex.release();
		for (task in _tasks)
			if (task != null) task.complete(task);
	}

	/**
	 * Dispose of threads, mutexes and task deques.
	 */
	public function dispose():Void {
		// kill threads
		for (x in thread_pool)
			x.sendMessage("die");
		// make sure the thread_mutex is not aquired
		task_mutex.acquire();
		task_mutex.release();
		thread_pool = null;
		tasks = null;
		completed_tasks = null;
		task_mutex = null;
	}

	/**
	 * Will initialize the pool if it hasn't been already, and add the task to the queue
	 * @param t the task to execute
	 */
	public function addTask(t:ThreadTask):Void {
		t.error = false;
		task_mutex.acquire();
		tasks.add(t);
		task_mutex.release();
	}
}
