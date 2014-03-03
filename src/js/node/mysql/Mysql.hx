package js.node.mysql;

import js.Node;

typedef MysqlCreateParams = {
    @:optional var host : String; // localhost
    @:optional var port : Int; // 3306
	@:optional var localAddress : String; // Source IP adress to use for TCP connection
	@:optional var socketPath : String; // The path to a unix domain socket to connect to. When used host and port are ignored.
	var user: String; // The MySQL user to authenticate as.
	var password: String; // The password of that MySQL user.
	var database: String; // Name of the database to use for this connection (Optional).
	@:optional var charset: String; // The charset for the connection. (Default: 'UTF8_GENERAL_CI'. Value needs to be all in upper case letters!)
	@:optional var timezone: String; // The timezone used to store local dates. (Default: 'local')
	@:optional var connectTimeout: Int; // The milliseconds before a timeout occurs during the initial connection to the MySQL server. (Default: no timeout)
	@:optional var stringifyObjects: Bool; // Stringify objects instead of converting to values. See issue #501. (Default: 'false')
	@:optional var insecureAuth: Bool; // Allow connecting to MySQL instances that ask for the old (insecure) authentication method. (Default: false)
	@:optional var typeCast: Bool; // Determines if column values should be converted to native JavaScript types. (Default: true)
	@:optional var queryFormat: Dynamic; //  A custom query format function. See Custom format.
	@:optional var supportBigNumbers: Bool; // When dealing with big numbers (BIGINT and DECIMAL columns) in the database, you should enable this option (Default: false).
	@:optional var bigNumberStrings: Bool; // Enabling both supportBigNumbers and bigNumberStrings forces big numbers (BIGINT and DECIMAL columns) to be always returned as JavaScript String objects (Default: false). Enabling supportBigNumbers but leaving bigNumberStrings disabled will return big numbers as String objects only when they cannot be accurately represented with JavaScript Number objects (which happens when they exceed the [-2^53, +2^53] range), otherwise they will be returned as Number objects. This option is ignored if supportBigNumbers is disabled.
	@:optional var dateStrings: Bool; // Force date types (TIMESTAMP, DATETIME, DATE) to be returned as strings rather then inflated into JavaScript Date objects. (Default: false)
	@:optional var debug: Bool; // Prints protocol details to stdout. (Default: false)
	@:optional var trace: Bool; // Generates stack traces on Error to include call site of library entrance ("long stack traces"). Slight performance penalty for most calls. (Default: true)
	@:optional var multipleStatements: Bool; // Allow multiple mysql statements per query. Be careful with this, it exposes you to SQL injection attacks. (Default: false)
	@:optional var flags: Dynamic; // List of connection flags to use other than the default ones. It is also possible to blacklist default ones. For more information, check Connection Flags.
	@:optional var ssl: Dynamic; // object with ssl parameters ( same format as crypto.createCredentials argument ) or a string containing name of ssl profile. Currently only 'Amazon RDS' profile is bundled, containing CA from https://rds.amazonaws.com/doc/rds-ssl-ca-cert.pem
};

// emit: "error" (err), "field" (field), "row" (row), "end" ([result])
typedef MysqlQuery = {
	@:overload(function(eventName:String, cb:Array<String>->Void) : MysqlQuery {})
	@:overload(function(eventName:String, cb:Array<Dynamic>->Void) : MysqlQuery {})
	function on(eventName:String, errorCb:NodeErr->Void) : MysqlQuery;
	/*
	  .on('error', function(err) {
	  // Handle error, an 'end' event will be emitted after this as well
	  })
	  .on('fields', function(fields) {
	  // the field packets for the rows to follow
	  })
	  .on('result', function(row) {
	  // Pausing the connnection is useful if your processing involves I/O
	  connection.pause();

	  processRow(row, function() {
      connection.resume();
	  });
	  })
	  .on('end', function() {
	  // all rows have been received
	  });
	*/
};

typedef MysqlResult = {
	> Array<Dynamic>,
	@:optional var insertId: Int;
};

typedef MysqlConnection = {
	function connect(cb:NodeErr->Void) : Void;
	
	function beginTransaction(cb:NodeErr->Void) : Void;
	function rollback(cb:Void->Void) : Void;
	function commit(cb:NodeErr->Void) : Void;
	
	function escape(data:Dynamic) : String;
	function destroy() : Void;
	function end(?f:NodeErr->Void) : Void;

	@:overload(function(q:String, params:Array<Dynamic>, cb:NodeErr->MysqlResult) : MysqlQuery {})
	@:overload(function(q:String, params:Dynamic, cb:NodeErr->MysqlResult) : MysqlQuery {})
	@:overload(function(q:String, cb:NodeErr->MysqlResult) : MysqlQuery {})
	@:overload(function(q:String, params:Array<Dynamic>) : MysqlQuery {})
	@:overload(function(q:String, params:Dynamic) : MysqlQuery {})
	function query(q:String) : MysqlQuery;

	function pause() : Void;
	function resume() : Void;
};

typedef MysqlPoolConnection = { > MysqlConnection,
	function release() : Void;
};

typedef MysqlPool = {
	function escape(data:Dynamic) : String;
	function getConnection(f:NodeErr->MysqlPoolConnection->Void) : Void;

	// pool.on('connection', function(connection){})
	function on(eventName:String, f:MysqlPoolConnection->Void) : Void;
};

typedef MysqlPoolCreateParams = {
	> MysqlCreateParams,
	@:optional var waitForConnections: Bool; // Determines the pool's action when no connections are available and the limit has been reached. If true, the pool will queue the connection request and call it when one becomes available. If false, the pool will immediately call back with an error. (Default: true)
	@:optional var connectionLimit: Int; // The maximum number of connections to create at once. (Default: 10)
	@:optional var queueLimit: Int; // The maximum number of connection requests the pool will queue before returning an error from getConnection. If set to 0, there is no limit to the number of queued connection requests. (Default: 0)
};

typedef MysqlPoolClusterParams = {
	@:optional var canRetry: Bool; // If true, PoolCluster will attempt to reconnect when connection fails. (Default: true)
	@:optional var removeNodeErrorCount: Int; // If connection fails, node's errorCount increases. When errorCount is greater than removeNodeErrorCount, remove a node in the PoolCluster. (Default: 5)
	@:optional var defaultSelector: String; /* The default selector. (Default: RR)
    RR: Select one alternately. (Round-Robin)
RANDOM: Select the node by random function.
ORDER: Select the first node available unconditionally.
											*/
};

typedef MysqlPoolCluster = {
	function add(?serverId:String, config:MysqlCreateParams) : Void;
	function getConnection(?serverIdWildcard:String, ?order:String, cb:NodeErr->MysqlConnection->Void) : Void;
	// on("remove", function(nodeId){})
	function on(eventName:String, nodeId:String->Void) : Void;
	function of(serverIdWildcard:String, order:String) : MysqlPool;
	function end() : Void;
};

class Mysql {
    public static function createConnection(params:MysqlCreateParams) : MysqlConnection {
        var c = Node.require("mysql");
        return untyped c.createConnection(params);
    }

	/*
	  Use a connection URL instead of a parameter object.
	  
	  'mysql://user:pass@host/db?debug=true&charset=BIG5_CHINESE_CI&timezone=-0700'	  
	 */
    public static function createConnectionWithUrl(url:String) : MysqlConnection {
        var c = Node.require("mysql");
        return untyped c.createConnection(url);
    }

	public static function createPool(params:MysqlPoolCreateParams) : MysqlPool {
		var c = Node.require("mysql");
		return untyped c.createPool(params);
	}

	public static function createPoolCluster(params:MysqlPoolClusterParams) : MysqlPoolCluster {
		var c = Node.require("mysql");
		return untyped c.createPoolCluster(params);
	}
}