package js.node;

typedef Err = Dynamic;

class Jade {
    inline public static function compile(src:String, options:Dynamic) : Dynamic -> String {
        return __compile(src, options);
    }

    inline public static function renderFile(path:String, options:Dynamic, cb:Err-> (String) ->Void) : Void {
        __renderFile(path, options, cb);
    }

    static var __compile : Dynamic;
    static var __renderFile : Dynamic;

    static function __init__(){
        var api = Node.require("jade");
        __compile = api.compile;
        __renderFile = api.renderFile;
    }
}