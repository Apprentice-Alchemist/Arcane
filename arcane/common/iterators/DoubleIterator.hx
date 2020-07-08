package arcane.common.iterators;

class DoubleIterator<T>{
    var it1:Iterator<T>;
    var it2:Iterator<T>;
    public function new(it1:Iterator<T>,it2:Iterator<T>){
        this.it1 = it1;
        this.it2 = it2;
    }
    public function hasNext():Bool {
        return it1.hasNext() ? true : it2.hasNext();
    }
    public function next():T {
        return it1.hasNext() ? it1.next() : it2.next();
    }
}