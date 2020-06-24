package arcane.adv;

import arcane.xml.XmlPath;
import hscript.Parser;
import hscript.Interp;

class XmlEventHandler {
    public var interp:Interp;
    public var parser:Parser;

    var _varstore:Map<String,Dynamic>;
    public var vars(get,null):Map<String,Dynamic> = new Map();

    public function get_vars(){
        if(varstore != null) return varstore;
        else return vars;
    }
    public function new(?varstore:Map<String,Dynamic>) {
        interp = new Interp();
        parser = new Parser();
        _varstore = varstore;
        EventHandler.loadVars(interp.variables);
    }
    public function executeXml(xml:Xml){
        var it = xml.elements();
        while(it.hasNext()){
            var node = it.next();
            switch(node.nodeName){
                case "section": executeXml(node);
                case "action": EventHandler.execute(node.firstChild(),this.vars);
                case "stop": break;
            }
        }
    }
}