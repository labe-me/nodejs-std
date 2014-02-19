/*
  Author: Laurent Bedubourg <lbedubourg@gmail.com>
 */
package redis;

import js.Node;
import js.node.redis.Redis;
import js.node.redis.RedisPromiseWrapper;
import promhx.*;
import promhx.mdo.*;

class Manager<T : Object> {
    public static var pdb : RedisPromiseWrapper;

	static var db : RedisClient;
    static var managers = new Map<String, Manager<Dynamic>>();

    var managedClass : Class<Dynamic>;
    public var tableName : String;
    var autoIncrementID = true;
    var expireSeconds : Int = 0;

    public static function init(redis:RedisClient){
        db = redis;
        pdb = new RedisPromiseWrapper(redis);
    }

    public function new(cls:Class<Dynamic>){
        managedClass = cls;
        tableName = Type.getClassName(cls); // may be different later
        var meta = haxe.rtti.Meta.getType(cls);
        if (meta.expire != null && meta.expire[0] != null){
            expireSeconds = meta.expire[0];
        }
        var fields = haxe.rtti.Meta.getFields(cls);
        if (fields.id == null)
            throw 'ERROR: ${tableName} has no id field defined';
        autoIncrementID = !Reflect.hasField(fields.id, "noAutoIncrement");
        managers.set(Type.getClassName(cls), this);
    }

    public inline function get(id:Dynamic) : Promise<T> {
		if (id == null)
			return Promise.promise(null);
        return pdb.hgetall('${tableName}:${id}').then(function(res){
			if (res == null)
				return null;
			var result = Type.createInstance(managedClass, []);
			Macro.fillObject(result, res);
			return result;
        });
    }

    public function oldGet(id:Dynamic, cb:NodeErr->T->Void){
        if (id == null)
            return cb(null, null);
        db.hgetall('${tableName}:${id}', function(err, res){
            if (err != null)
                return cb(err, null);
            if (res == null)
                return cb(null, null);
            try {
                var result = Type.createInstance(managedClass, []);
                Macro.fillObject(result, res);
                cb(null, result);
            }
            catch (e:Dynamic){
                cb(e, null);
            }
        });
    }
	
    public function fetchMany(ids:Array<Dynamic>) : Promise< Array<T> > {
		if (ids == null || ids.length == 0)
			return Promise.promise([]);
		var p = new Promise();
        var ids = ids.copy();
        var result = [];
        var next = null;
        next = function(){
            if (ids.length == 0){
				p.resolve(result);
				return;
			}
            get(ids.shift()).then(function(t){
                if (t != null)
                    result.push(t);
                return next();
            }).catchError(function(e){
				p.reject(e);
			});
        }
        next();
		return p;
    }

	@:allow(redis.Object)
	function insert(obj:T){
		if (autoIncrementID)
			return insertWithAutoID(obj);
		else if ((cast obj).id == null){
			var p = new Promise();
			p.reject('Tryied to insert ${tableName} with null id (noAutoIncrement)');
			return p;
		}
		else
			return update(obj);
	}

	@:allow(redis.Object)
	function update(obj:T, ?fields:Array<String>){
		return PromiseM.dO({
			// store fields
			pdb.hmset('${tableName}:${(cast obj).id}', Macro.toObject(obj, fields));
			// set expiration when required
			if (expireSeconds > 0)
				pdb.expire('${tableName}:${(cast obj).id}', expireSeconds);
			else
				Promise.promise(null);
			// update indexes
			obj.updateIndexes();
		});
	}
	
	@:allow(redis.Object)
	function delete(obj:T) : Promise<Int> {
		return PromiseM.dO({
			n <= pdb.del('${tableName}:${(cast obj).id}');
			if (n > 0)
				obj.deleteIndexes();
			else
				Promise.promise(null);
			ret(n);
		});
	}
	
	function insertWithAutoID(obj:T){
		return incrementId().pipe(function(id){
			(cast obj).id = id;
			return update(obj);
		});
	}

	function incrementId() : Promise<Int> {
		return pdb.incr('${tableName}:_uid');
	}

    public function getMaxId() : Promise<Int> {
		return PromiseM.dO({
			id <= {
				if (!autoIncrementID)
					throw '${tableName} has not an autoIncrementID, maxId() is not available';
				pdb.get('${tableName}:_uid');
			};
			ret(if (id == null) 0 else Std.parseInt(id));
		});
    }

    public function oldEach<V>(f:T->Promise<V>) : Promise<Int> {
        var n = 0;
        var p = new Promise();
        function next(id, maxId){
            if (id > maxId){
                p.resolve(n);
                return;
            }
            promhx.mdo.PromiseM.dO({
                o <= get(id);
                {
                    if (o != null){
                        ++n;
                        f(o);
                    }
                    else
                        Promise.promise(null);
                };
            }).then(function(_){
                next(id+1, maxId);
            }).catchError(function(err){
                p.reject(err);
            });
        }
        getMaxId().then(function(maxId) next(1, maxId)).catchError(p.reject);
        return p;
    }

    public function each<V>(startId=1, limit:Int=-1, incr=1, f:T->Promise<V>) : Promise<Int> {
        var n = 0;
        var p = new Promise();
        function next(id, maxId){
            if (incr > 0 && id > maxId){
                p.resolve(n);
                return;
            }
			if (incr < 0 && id < 1){
				p.resolve(n);
				return;
			}
			if (limit >= 0 && n >= limit){
				p.resolve(n);
				return;
			}
            promhx.mdo.PromiseM.dO({
                o <= get(id);
                {
                    if (o != null){
                        ++n;
                        f(o);
                    }
                    else 
                        Promise.promise(null);
                };
            }).then(function(_){
                next(id+incr, maxId);
            }).catchError(function(err){
                p.reject(err);
            });
        }
        getMaxId().then(
			function(maxId) next((startId == -1) ? maxId : startId, maxId)
		).catchError(p.reject);
        return p;
    }

	// Old method with callbacks, deprecated

    public function oldInsert(obj:T, ?cb:NodeErr->Void){
        if (cb == null)
            cb = function(err) if (err != null) throw err;
        if (autoIncrementID)
            oldInsertWithAutoID(obj, cb);
        else if ((cast obj).id == null)
            cb('Tryied to insert ${tableName} with null id (noAutoIncrement)');
        else
            oldUpdate(obj, cb);
    }

    function oldUpdate(obj:T, ?fields:Array<String>, ?cb:NodeErr->Void){
        if (cb == null)
            cb = function(err) if (err != null) throw err;
        var next = oldUpdateIndexes.bind(obj, cb);
        db.hmset('${tableName}:${(cast obj).id}', Macro.toObject(obj, fields), function(err, res){
            if (err != null)
                return next(err);
            if (expireSeconds > 0){
                return db.expire('${tableName}:${(cast obj).id}', expireSeconds, function(err, _) next(err));
            }
            return next(null);
        });
    }

    function oldUpdateIndexes(obj:T, cb:NodeErr->Void, err:NodeErr){
        if (err != null)
            return cb(err);
        obj.updateIndexes()
            .then(function(_) cb(null))
            .catchError(cb);
    }

    function oldDelete(obj:T, ?cb:IntegerReply){
        if (cb == null)
            cb = function(err, v) if (err != null) throw err;
        var next = oldDeleteIndexes.bind(obj, cb);
        db.del('${tableName}:${(cast obj).id}', next);
    }

    function oldDeleteIndexes(obj:T, cb:IntegerReply, err:NodeErr, v:Int){
        if (err != null)
            return cb(err, v);
        obj.deleteIndexes()
            .then(function(_) cb(null, v))
            .catchError(function(err) cb(err, v));
    }

    function oldInsertWithAutoID(obj:T, ?cb:NodeErr->Void){
        if (cb == null)
            cb = function(err) if (err != null) throw err;
        oldIncrementId(function(err, id){
            if (err != null)
                return cb(err);
            (cast obj).id = id;
            oldUpdate(obj, cb);
        });
    }

    function oldIncrementId(cb:NodeErr->Int->Void){
        if (cb == null)
            cb = function(err, v) if (err != null) throw err;
        db.incr('${tableName}:_uid', cb);
    }

}
