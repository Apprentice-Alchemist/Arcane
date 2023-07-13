import sys.thread.Thread;

function main() {
	trace("Hello World!");
	Thread.create(() -> {
		trace("thread");
		throw "Hello?";
	});
	// hl.Api.breakPoint();
	Thread.current().events.repeat(() -> {}, 5);
}