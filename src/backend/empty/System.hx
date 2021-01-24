package backend.empty;

import arcane.spec.ISystem;

class System implements ISystem {
    public function isFeatureSupported(f) return false;
    public function new(){}
    public function init(opts,cb:Void->Void) cb();
    public function shutdown(){}
    public function createGraphicsDriver() return null;
    public function createAudioDriver() return null;
    public function language():String return "en_US";
    public function time():Float return 0.;
}
