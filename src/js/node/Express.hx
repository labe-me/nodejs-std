package js.node;

import js.node.Connect;
import js.Node;
import js.node.EveryAuth;

/**
 * ...
 * @author sledorze
 */

typedef ExpressHttpServerReq = { > NodeHttpServerReq,
	var session : Dynamic;
	var body : Dynamic;
	var query : Dynamic; // must be activated by app.use(...)
	var params : Dynamic; // must be activated by app.use(...)
}

typedef ExpressHttpServerResp = { > NodeHttpServerResp,
	function render(name : String, params : Dynamic) : Void;
	@:overload(function (code:Int, url:String) : Void {})
	function redirect(url : String) : Void;
	function header(name:String, value:String) : Void;
	@:overload(function () : Void {})
	@:overload(function (code : Int, value : String) : Void {})
	@:overload(function (code : Int, value : Dynamic) : Void {})
	function send(value : Dynamic) : Void;
}


typedef AddressAndPort = {
  address : String,
  port : Int
};

typedef ExpressRouteCallback = ExpressHttpServerReq -> ExpressHttpServerResp -> Void;

typedef ExpressServer = {
	@:overload(function(f: Dynamic->ExpressHttpServerReq->ExpressHttpServerResp->Dynamic->Void):Void { } )
	@:overload(function(f: ExpressHttpServerReq->ExpressHttpServerResp->Dynamic->Void):Void { } )
	function use (?middlewareMountPoint :Dynamic, middleware :Dynamic) :ConnectServer;

	function set(name : String, value : String) : Void;

    @:overload(function(path:String, cb:MiddleWare, f:ExpressRouteCallback):Void{})
    @:overload(function(path:String, cbs:Array<MiddleWare>, f:ExpressRouteCallback):Void{})
	function get(path : String, f : ExpressRouteCallback) : Void;

    @:overload(function(path:String, cb:MiddleWare, f:ExpressRouteCallback):Void{})
    @:overload(function(path:String, cbs:Array<MiddleWare>, f:ExpressRouteCallback):Void{})
	function post(path : String, f : ExpressRouteCallback) : Void;


	function listen (port :Int, ?address :String) :Void;

  function address() : AddressAndPort;
}

typedef CookieSessionMiddleWareParams = {
	@:optional var key : String; // default to "connect.sess"
	var secret : String; // prevent cookie tampering
	@:optional var cookie : Dynamic; // session cookie settings, defaulting to `{ path: '/', httpOnly: true, maxAge: null }`
	@:optional var proxy : Bool; // trust the reverse proxy when setting secure cookies (via "x-forwarded-proto")
}

typedef BodyParserMiddleWareParams = {
	@:optional var defer:Bool;
	@:optional var uploadDir:String;
	@:optional var limit:String;
}

extern
class Express {
	public function cookieParser() :MiddleWare;
	// populate req.session with the content of a signed cookie set on the browser
	public function cookieSession(?params:CookieSessionMiddleWareParams) :MiddleWare;
	public function bodyParser(?config:BodyParserMiddleWareParams) :MiddleWare;
	public function session(?params :Dynamic) :MiddleWare;
	public function router(routes :Dynamic->Void) :Void;
	public function Static (path :String, ?options :Dynamic) :MiddleWare;
	public function errorHandler (options :Dynamic) :MiddleWare;

	public function logger() : MiddleWare;


    inline public static function require() : Express {
        return js.Node.require("express");
    }

    inline public static function createApplication(express:Express) : ExpressServer {
        return untyped __js__("express()");
    }

	inline public static function static_(exp : Express, path : String, ?option : Dynamic) : MiddleWare {
		var x = exp;
		var p = path;
		var o = option;
		return untyped __js__("x.static(p, o)");
	}
}
