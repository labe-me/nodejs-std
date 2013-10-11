/*
  Author: Laurent Bedubourg <lbedubourg@gmail.com>
 */
package redis;
import js.Node;
import js.node.redis.Redis;

// value -> id
class UniqueIndex {
    public static function insert(manager, idxName:String, value:Dynamic, id:Dynamic, cb){
        if (value == null || id == null)
            return;
        redis.Manager.db.hset(manager.tableName+idxName, value, id, cb);
    }

    public static function delete(manager, idxName:String, value:Dynamic, cb){
        redis.Manager.db.hdel(manager.tableName+idxName, value, cb);
    }

    public static function get<T>(manager, idxName:String, value:Dynamic, cb:NodeErr->T->Void){
        redis.Manager.db.hget(manager.tableName+idxName, value, function(err:NodeErr, id:String){
            if (err != null || id == null)
                return cb(err, null);
            return manager.get(id, cb);
        });
    }
}

// sort(value) -> id
class SortedIndex {
    public static function delete(manager, idxName:String, id:Dynamic, cb){
        redis.Manager.db.zrem(manager.tableName+idxName, id, cb);
    }

    public static function insert(manager, idxName:String, id:Dynamic, value:Int, cb){
        if (value == null || id == null)
            return;
        redis.Manager.db.zadd(manager.tableName+idxName, value, id, cb);
    }

    public static function browseIds(manager, idxName:String, start:Int, limit:Int, cb){
        redis.Manager.db.zrange(manager.tableName+idxName, start, start+limit-1, cb);
    }

    public static function count(manager, idxName:String, cb){
        redis.Manager.db.zcard(manager.tableName+idxName, cb);
    }
}

// parent -> children*
class HasManyRelation {
    public static function insert(manager, idxName:String, parentId:Dynamic, childId:Dynamic, cb){
        if (parentId == null || childId == null)
            return;
        redis.Manager.db.zadd('${manager.tableName}:${parentId}:_children', childId, childId, cb);
    }

    public static function delete(manager, idxName:String, parentId:Dynamic, childId:Dynamic, cb){
        redis.Manager.db.zrem('${manager.tableName}:${parentId}:_children', childId, cb);
    }

    public static function parentDestroyed(manager, idxName:String, parentId:Dynamic, cb){
        redis.Manager.db.del('${manager.tableName}:${parentId}:_children', cb);
    }

    public static function count(manager, idxName:String, parentId:Dynamic, cb){
        redis.Manager.db.zcard('${manager.tableName}:${parentId}:_children', cb);
    }
}

class Manager<T : Object> {
    public static var db : RedisClient;
    static var managers = new Map<String, Manager<Dynamic>>();

    var managedClass : Class<Dynamic>;
    public var tableName : String;
    var autoIncrementID = true;
    var expireSeconds : Int = 0;

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

    public function get(id:Dynamic, cb:NodeErr->T->Void){
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

    public function fetchMany(ids:Array<Dynamic>, cb:NodeErr->Array<T>->Void){
        var ids = ids.copy();
        var result = [];
        var next = null;
        next = function(){
            if (ids.length == 0)
                return cb(null, result);
            return get(ids.shift(), function(err, t){
                if (err != null)
                    return cb(err, null);
                if (t != null)
                    result.push(t);
                return next();
            });
        }
        next();
    }

    public function insert(obj:T, ?cb:NodeErr->T->Void){
        if (cb == null)
            cb = function(err, v) if (err != null) throw err;
        if (autoIncrementID)
            insertWithAutoID(obj, cb);
        else if ((cast obj).id == null)
            cb('Tryied to insert ${tableName} with null id (noAutoIncrement)', obj);
        else
            update(obj, cb);
    }

    function update(obj:T, ?cb:NodeErr->T->Void){
        if (cb == null)
            cb = function(err, v) if (err != null) throw err;
        var next = updateIndexes.bind(obj, cb);
        db.hmset('${tableName}:${(cast obj).id}', Macro.toObject(obj), function(err, res){
            if (err != null)
                return next(err);
            if (expireSeconds > 0){
                return db.expire('${tableName}:${(cast obj).id}', expireSeconds, function(err, _) next(err));
            }
            return next(null);
        });
    }

    function updateIndexes(obj:T, cb:NodeErr->T->Void, err:NodeErr){
        if (err != null)
            return cb(err, obj);
        obj.updateIndexes(function(err:NodeErr) cb(err, obj));
    }

    function delete(obj:T, ?cb:IntegerReply){
        if (cb == null)
            cb = function(err, v) if (err != null) throw err;
        var next = deleteIndexes.bind(obj, cb);
        db.del('${tableName}:${(cast obj).id}', next);
    }

    function deleteIndexes(obj:T, cb:IntegerReply, err:NodeErr, v:Int){
        if (err != null)
            return cb(err, v);
        obj.deleteIndexes(function(err) cb(err, v));
    }

    function insertWithAutoID(obj:T, ?cb:NodeErr->T->Void){
        if (cb == null)
            cb = function(err, v) if (err != null) throw err;
        incrementId(function(err, id){
            if (err != null)
                return cb(err, obj);
            (cast obj).id = id;
            update(obj, cb);
        });
    }

    function incrementId(cb:NodeErr->Int->Void){
        if (cb == null)
            cb = function(err, v) if (err != null) throw err;
        db.incr('${tableName}:_uid', cb);
    }
}
