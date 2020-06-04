package arcane.display;
#if !heaps
#error "Heaps is required!"
#end
class Sprite extends h2d.Drawable {
    override public function new(?parent:h2d.Object) {
        super(parent);
    }
    public function playAnimation(name:String){

    }
    override private function sync(ctx) {
        super.sync(ctx);
    }
    override private function draw(ctx){
        // emitTile(ctx,null);
    }
}