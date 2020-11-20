package arcane.d2d;

import h2d.RenderContext;

class ProgressBar extends h2d.Object {
    public var progress:Float = 0;
    var g:h2d.Graphics;

    override public function new(s) {
        super(s);
        g = new h2d.Graphics(this);
    }

    override function sync(ctx:RenderContext) {
        g.clear();
        g.lineStyle(1,0x00ff00);
        g.drawRect(0,0,500,20);
        g.lineStyle();
        g.beginFill(0x0000ff);
        g.drawRect(0,0,500 * progress,20);
        g.endFill();
        super.sync(ctx);
    }
}
