/*
  Author: Laurent Bedubourg <lbedubourg@gmail.com>
 */
package redis;

import js.Node;
import js.node.redis.Redis;
import promhx.*;


// sort(value) -> id
class SortedIndex {
    inline public static function pdelete(manager, idxName:String, id:Dynamic){
        var p = new Promise();
        delete(manager, idxName, id, function(err, v) if (err != null) p.reject(err) else p.resolve(v));
        return p;
    }

    inline public static function pinsert(manager, idxName:String, id:Dynamic, value:Int){
        var p = new Promise();
        insert(manager, idxName, id, value, function(err, v) if (err != null) p.reject(err) else p.resolve(v));
        return p;
    }

    inline public static function pbrowseIdsReverse(manager, idxName:String, start:Int, limit:Int, cb){
        var p = new Promise();
        browseIdsReverse(manager, idxName, start, limit, function(err, v) if (err != null) p.reject(err) else p.resolve(v));
        return p;
    }

    inline public static function pcount(manager, idxName:String){
        var p = new Promise();
        count(manager, idxName, function(err, v) if (err != null) p.reject(err) else p.resolve(v));
        return p;
    }

    inline public static function pbrowse<T:Object>(manager:Manager<T>, idxName:String, start:Int, limit:Int){
        var p = new Promise();
        browse(manager, idxName, start, limit, function(err, v) if (err != null) p.reject(err) else p.resolve(v));
        return p;
    }

    inline public static function pbrowseReverse<T:Object>(manager:Manager<T>, idxName:String, start:Int, limit:Int){
        var p = new Promise();
        browseReverse(manager, idxName, start, limit, function(err, v) if (err != null) p.reject(err) else p.resolve(v));
        return p;
    }

    public static function delete(manager, idxName:String, id:Dynamic, cb){
        redis.Manager.db.zrem(manager.tableName+":"+idxName, id, cb);
    }

    public static function insert(manager, idxName:String, id:Dynamic, value:Int, cb:IntegerReply){
        if (value == null || id == null)
            return cb(null, 0);
        redis.Manager.db.zadd(manager.tableName+":"+idxName, value, id, cb);
    }

    public static function browseIds(manager, idxName:String, start:Int, limit:Int, cb){
        redis.Manager.db.zrange(manager.tableName+":"+idxName, start, start+limit-1, cb);
    }

    public static function browseIdsReverse(manager, idxName:String, start:Int, limit:Int, cb){
        redis.Manager.db.zrevrange(manager.tableName+":"+idxName, start, start+limit-1, cb);
    }

    public static function count(manager, idxName:String, cb){
        redis.Manager.db.zcard(manager.tableName+":"+idxName, cb);
    }

    public static function browse<T:Object>(manager:Manager<T>, idxName:String, start:Int, limit:Int, cb){
        browseIds(manager, idxName, start, limit, function(err, ids){
            if (err != null || ids == null)
                return cb(err, null);
            return manager.fetchMany(ids, cb);
        });
    }

    public static function browseReverse<T:Object>(manager:Manager<T>, idxName:String, start:Int, limit:Int, cb){
        browseIdsReverse(manager, idxName, start, limit, function(err, ids){
            if (err != null || ids == null)
                return cb(err, null);
            return manager.fetchMany(ids, cb);
        });
    }
}
