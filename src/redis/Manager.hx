/*
  Author: Laurent Bedubourg <lbedubourg@gmail.com>
 */
package redis;
import js.Node;
import js.node.redis.Redis;

class Manager<T : Object> {
    public static var db : RedisClient;
    static var managers = new Map<String, Manager<Dynamic>>();

    var managedClass : Class<Dynamic>;
    var tableName : String;
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