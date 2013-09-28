package js.node.mysql;

import js.Node;

typedef MysqlRows = Array<Dynamic>;
typedef MysqlFields = Dynamic;
typedef MysqlInfo = Dynamic;
typedef MysqlErrReply = NodeErr->Void; // err
typedef MysqlSingleReply = NodeErr->MysqlInfo->Void; // err, result
typedef MysqlMultiReply = NodeErr->MysqlRows->MysqlFields->Void; // err, rows, fields

// emit: "error" (err), "field" (field), "row" (row), "end" ([result])
typedef MysqlQuery = { > NodeEventEmitter,
}

// emit: error,
typedef MysqlClient = { > NodeEventEmitter,
    public var host : String;
    public var port : Int;
    public var user : String;
    public var password : String;
    public var database : String;
    public var debug : Bool;
    public var ending : Bool;
    public var connected : Bool;

    @:overload(function(cb:MysqlErrReply) : Void {})
    public function ping(?cb:MysqlSingleReply) : Void;

    @:overload(function(sql:String, params:Dynamic, cb:MysqlErrReply) : MysqlQuery {})
    @:overload(function(sql:String, params:Dynamic, cb:MysqlSingleReply) : MysqlQuery {})
    @:overload(function(sql:String, params:Dynamic, cb:MysqlMultiReply) : MysqlQuery {})
    @:overload(function(sql:String, cb:MysqlErrReply) : MysqlQuery {})
    @:overload(function(sql:String, cb:MysqlSingleReply) : MysqlQuery {})
    public function query(sql:String, cb:MysqlMultiReply) : MysqlQuery;

    public function format(sql:String, params:Array<Dynamic>) : String;

    public function escape(val:Dynamic) : String;

    @:overload(function(dbname:String, cb:MysqlErrReply) : Void {})
    public function useDatabase(dbname:String, cb:MysqlSingleReply) : Void;

    public function destroy() : Void;

    @:overload(function(cb:MysqlErrReply) : Void {})
    public function end(?cb:MysqlSingleReply) : Void;
}

typedef MysqlCreateParams = {
    var host : String;
    var port : Int;
    var user : String;
    var password : String;
    var database : String;
}

class Mysql {
    public static function createClient(params:MysqlCreateParams) : MysqlClient {
        var c = Node.require("mysql");
        return untyped c.createClient(params);
    }
}