package mysql;

import promhx.*;

typedef Params = js.node.mysql.Mysql.MysqlCreateParams;
typedef PoolParams = js.node.mysql.Mysql.MysqlPoolCreateParams;

class Connection {
	var connection : js.node.mysql.Mysql.MysqlConnection;
		
	public function new(?cx:js.node.mysql.Mysql.MysqlConnection=null, ?params:Params=null){
		connection = cx;
		if (cx == null)
			connection = js.node.mysql.Mysql.createConnection(params);
	}

	inline public function escape(data:Dynamic) : String {
		return connection.escape(data);
	}
	
	public function connect() : Promise<Connection> {
		var p = new Promise();
		connection.connect(function(err){
			if (err != null)
				p.reject(err);
			else
				p.resolve(this);
		});
		return p;
	}

	public function beginTransaction() : Promise<Connection> {
		var p = new Promise();
		connection.beginTransaction(function(err){
			if (err != null)
				p.reject(err);
			else
				p.resolve(this);
		});
		return p;
	}

	public function rollback() : Promise<Connection> {
		var p = new Promise();
		connection.rollback(function(){
			p.resolve(this);
		});
		return p;
	}

	public function commit() : Promise<Connection> {
		var p = new Promise();
		connection.beginTransaction(function(err){
			if (err != null)
				p.reject(err);
			else
				p.resolve(this);
		});
		return p;
	}

	public inline function destroy() : Void {
		connection.destroy();
	}

	public inline function end() : Promise<Connection> {
		var p = new Promise();
		connection.end(function(err){
			if (err != null)
				p.reject(err);
			else
				p.resolve(this);
		});
		return p;
	}

	public inline function pause() : Void {
		connection.pause();
	}

	public inline function resume() : Void {
		connection.resume();
	}

	public function query(sql:String, ?params:Dynamic) : Promise<js.node.mysql.Mysql.MysqlResult> {
		var p = new Promise();
		(cast connection).query(sql, params, function(err, res){
			if (err != null)
				p.reject(err);
			else
				p.resolve(res);
		});
		return p;
	}

	public function stream(sql:String, ?params:Dynamic) : Stream<StreamPart> {
		var query = connection.query(sql, params);
		var walker = new ResultStream(this, query);
		return walker;
	}
}

typedef StreamPart = { fields:Array<String>, row:Dynamic };

private class ResultStream extends promhx.Stream<StreamPart> {
	var fields : Array<String>;
	public var stream : promhx.Stream<StreamPart>;
	var connection : Connection;

	public function new(cx, query:js.node.mysql.Mysql.MysqlQuery){
		super();
		connection = cx;
		query.on('error', function(err:js.Node.NodeErr){
			this.handleError(err);
		});
		query.on('fields', function(fields:Array<String>){
			this.fields = fields;
		});
		query.on('result', function(row:Array<Dynamic>){
			this.update({ fields:fields, row:row });
		});
		query.on('end', function(_){
			this.end();
		});
	}
	
	override public function pause(?set:Bool){
		super.pause(set);
		if (_pause)
			connection.pause();
		else
			connection.resume();
	}
}

class PoolConnection extends Connection {
	public function new(cx:js.node.mysql.Mysql.MysqlPoolConnection){
		super(cx);
	}

	inline public function release(){
		(cast connection).release();
	}
}

class Pool {
	var pool : js.node.mysql.Mysql.MysqlPool;
	
	public function new(params:PoolParams){
		pool = js.node.mysql.Mysql.createPool(params);
	}

	public inline function escape(data:Dynamic) : String {
		return pool.escape(data);
	}

	public function getConnection() : Promise<PoolConnection> {
		var p = new Promise();
		pool.getConnection(function(err, cx){
			if (err != null)
				p.reject(err);
			else
				p.resolve(new PoolConnection(cx));
		});
		return p;
	}
}
