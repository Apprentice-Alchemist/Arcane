package arcane.xml;

class XmlPath {
    public var xml:Xml;
    public var path:String;
    public var nodeName:String;
    public function new(_path:String,_xml:Xml){
    xml = _xml;
    path = _path;
    nodeName = xml.nodeName;
    }
    public function get(att:String){
        return xml.get(att);
    }
    public function set(att:String,s:String){
        return xml.set(att,s);
    }
    public function elements(){
        return xml.elements();
    } 
    public function elementsNamed(name:String){
        return xml.elementsNamed(name);
    }
    public function firstElement(){
        return xml.firstElement();
    }
    public function getPath(){
        return path;
    }
    // public function
}