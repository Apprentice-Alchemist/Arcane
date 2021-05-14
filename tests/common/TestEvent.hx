package common;

import arcane.signal.Event;

class TestEvent extends utest.Test {
	function testEvent() {
        var e = new Event<Int,Float>();
        e.add((i, f) -> assert(i == 5 && f == 10));
        e.trigger(5,10.0);
    }
    
    function testEvent2() {
        var e = new Event<(i:Int,name:Float)->Void>();
        e.add((i, name) -> assert(i == 5 && name == 10.0));
        e.trigger(5,10.0);
    }
}