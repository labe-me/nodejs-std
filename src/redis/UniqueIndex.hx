/*
  Author: Laurent Bedubourg <lbedubourg@gmail.com>
 */
package redis;

import js.Node;
import js.node.redis.Redis;
import promhx.*;

// value -> id
class UniqueIndex {
    public static function insert(manager, idxName:String, value:Dynamic, id:Dynamic, cb:IntegerReply){
        if (value == null || id == null)
            return cb(null, 0);
        redis.Manager.db.hset(manager.tableName+":"+idxName, value, id, cb);
    }

    public static function delete(manager, idxName:String, value:Dynamic, cb){
        redis.Manager.db.hdel(manager.tableName+":"+idxName, value, cb);
    }

    public static function get<T>(manager, idxName:String, value:Dynamic, cb:NodeErr->T->Void){
        redis.Manager.db.hget(manager.tableName+":"+idxName, value, function(err:NodeErr, id:String){
            if (err != null || id == null)
                return cb(err, null);
            return manager.get(id, cb);
        });
    }

    public inline static function pget<T>(manager, idxName:String, value:Dynamic) : Promise<T> {
        var p = new Promise();
        get(manager, idxName, value, function(err, v) if (err != null) p.reject(err) else p.resolve(v));
        return p;
    }

    public inline static function pinsert(manager, idxName:String, value:Dynamic, id:Dynamic) : Promise<Int> {
        var p = new Promise();
        insert(manager, idxName, value, id, function(err, v) if (err != null) p.reject(err) else p.resolve(v));
        return p;
    }

    public inline static function pdelete(manager, idxName:String, value:Dynamic) : Promise<Int> {
        var p = new Promise();
        delete(manager, idxName, value, function(err, v) if (err != null) p.reject(err) else p.resolve(v));
        return p;
    }
}
