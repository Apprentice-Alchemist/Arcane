package arcane.adv;

class XmlPath {
	public var xml:Xml;
	public var path:String;
	public var nodeName(get, set):String;

	function set_nodeName(f:String)
		return xml.nodeName = f;

	function get_nodeName():String
		return xml.nodeName;

	public function new(_path:String, _xml:Xml) {
		xml = _xml;
		path = _path;
	}

	public function get(att:String) {
		return xml.get(att);
	}

	public function set(att:String, s:String) {
		return xml.set(att, s);
	}

	public function elements() {
		return xml.elements();
	}

	public function elementsNamed(name:String) {
		return xml.elementsNamed(name);
	}

	public function firstElement() {
		return xml.firstElement();
	}

	public function getPath() {
		return path;
	}
}
