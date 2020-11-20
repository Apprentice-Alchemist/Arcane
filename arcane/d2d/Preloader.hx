package arcane.d2d;

import h2d.RenderContext;
import hxd.res.DefaultFont;

class Preloader extends h2d.Object {
	var files:Array<String> = [];
	var bar:ProgressBar;
	var text:h2d.Text;

	override public function new(parent) {
		super(parent);
		bar = new ProgressBar(this);
		text = new h2d.Text(DefaultFont.get(), this);
		text.x = 50;
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
	}

	public function start() {
		Assets.preload(function(p) {
			bar.progress = p;
		}, function() {
			onEnd();
		});
	}

	public dynamic function onEnd() {}
}
