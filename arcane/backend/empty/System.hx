package arcane.backend.empty;

import arcane.spec.ISystem;

class System implements ISystem {
    public function isFeatureSupported(f) return false;
    public function new(){}
    public function init(cb:Void->Void) cb();
    public function shutdown(){}
    public function createGraphicsDriver() return null;
    public function createAudioDriver() return null;
}
