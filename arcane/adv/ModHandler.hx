package arcane.adv;

import arcane.xml.XmlPath;
import openfl.utils.Assets;
import openfl.utils.AssetType;
class ModHandler{
	public static var core_path:String = "data/core/core.xml";
    public static var mods_path:String = "data/mods/";
    public static var mod_file:String = "mod.xml";
    public static var action_map:Map<String,Dynamic> = null;
    public static function loadData(){
        ModHandler.loadActionMap();
        var asset_list = Assets.list();
        var mod_list = [core_path];
        for (o in asset_list){
            if (StringTools.startsWith(o,mods_path) && StringTools.endsWith(o,mod_file)){
                mod_list.push(o);
            }
        }
        for (o in mod_list){
            ModHandler.parseXml(ModHandler.makeXml(Xml.parse(Assets.getText(o)).elementsNamed('data').next(),o));
        }
    }
	public static var extraActions:(action_map:Map<String,Dynamic>)->Void;
    public static function loadActionMap(){
        if (action_map == null){
            action_map = new Map<String,Dynamic>();
        }
        action_map.clear();
        if(extraActions != null) extraActions(action_map);
    }
   
    public static function parseXml(s:XmlPath){
        for (o in s.elements()){
            if(action_map.exists(o.nodeName)){
                action_map.get(o.nodeName)(o,s.path);
            }        
        }
    }
    public static function makeXml(xml:Xml,path:String){
        return new XmlPath(path,xml);
    }
}