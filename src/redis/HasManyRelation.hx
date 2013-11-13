/*
  Author: Laurent Bedubourg <lbedubourg@gmail.com>
 */
package redis;

import js.Node;
import js.node.redis.Redis;
import promhx.*;


// parent -> children*
class HasManyRelation {
    public static function pinsert(manager, idxName:String, parentId:Dynamic, childId:Dynamic, ?sortValue:Int){
        var p = new Promise();
        insert(manager, idxName, parentId, childId, sortValue, function (err, v) if (err != null) p.reject(err) else p.resolve(v));
        return p;
    }

    public static function pdelete(manager, idxName:String, parentId:Dynamic, childId:Dynamic){
        var p = new Promise();
        delete(manager, idxName, parentId, childId, function (err, v) if (err != null) p.reject(err) else p.resolve(v));
        return p;
    }

    public static function pparentDestroyed(manager, idxName:String, parentId:Dynamic){
        var p = new Promise();
        parentDestroyed(manager, idxName, parentId, function (err, v) if (err != null) p.reject(err) else p.resolve(v));
        return p;
    }

    public static function pcount(manager, idxName:String, parentId:Dynamic){
        var p = new Promise<Int>();
        count(manager, idxName, parentId, function (err, v) if (err != null) p.reject(err) else p.resolve(v));
        return p;
    }

    public static function pbrowseIds(manager, idxName:String, parentId:Dynamic, start:Int, limit:Int) : Promise<Array<Dynamic>> {
        var p = new Promise();
        browseIds(manager, idxName, parentId, start, limit, function (err, v) if (err != null) p.reject(err) else p.resolve(v));
        return p;
    }

    public static function pscore(manager, idxName:String, parentId:Dynamic, childId:Dynamic) : Promise<Float> {
        var p = new Promise();
        score(manager, idxName, parentId, childId, function(err, v) if (err != null) p.reject(err) else p.resolve(Std.parseFloat(v)));
        return p;
    }

    public static function pbrowseIdsReverse<T:Object>(manager:Manager<T>, idxName:String, parentId:Dynamic, start:Int, limit:Int){
        var p = new Promise();
        browseIdsReverse(manager, idxName, parentId, start, limit, function (err, v) if (err != null) p.reject(err) else p.resolve(v));
        return p;

    }

    public static function pbrowse<T:Object, C:Object>(manager:Manager<T>, idxName:String, parentId:Dynamic, childManager:Manager<C>, start:Int, limit:Int) : Promise<Array<C>> {
        var p = new Promise();
        browse(manager, idxName, parentId, childManager, start, limit, function (err, v) if (err != null) p.reject(err) else p.resolve(v));
        return p;

    }

    public static function pbrowseReverse<T:Object, C:Object>(manager:Manager<T>, idxName:String, parentId:Dynamic, childManager:Manager<C>, start:Int, limit:Int) : Promise<Array<C>> {
        var p = new Promise();
        browseReverse(manager, idxName, parentId, childManager, start, limit, function (err, v) if (err != null) p.reject(err) else p.resolve(v));
        return p;
    }


    public static function insert(manager, idxName:String, parentId:Dynamic, childId:Dynamic, ?sortValue:Int, cb:IntegerReply){
        if (parentId == null || childId == null)
            return cb(null, 0);
        redis.Manager.db.zadd('${manager.tableName}:${idxName}:${parentId}', sortValue != null ? cast sortValue : childId, childId, cb);
    }

    public static function delete(manager, idxName:String, parentId:Dynamic, childId:Dynamic, cb){
        redis.Manager.db.zrem('${manager.tableName}:${idxName}:${parentId}', childId, cb);
    }

    public static function parentDestroyed(manager, idxName:String, parentId:Dynamic, cb){
        redis.Manager.db.del('${manager.tableName}:${idxName}:${parentId}', cb);
    }

    public static function count(manager, idxName:String, parentId:Dynamic, cb){
        redis.Manager.db.zcard('${manager.tableName}:${idxName}:${parentId}', cb);
    }

    public static function browseIds(manager, idxName:String, parentId:Dynamic, start:Int, limit:Int, cb){
        redis.Manager.db.zrange('${manager.tableName}:${idxName}:${parentId}', start, start+limit-1, cb);
    }

    public static function score(manager, idxName:String, parentId:Dynamic, childId:Dynamic, cb){
        redis.Manager.db.zscore('${manager.tableName}:${idxName}:${parentId}', childId, cb);
    }

    public static function browseIdsReverse<T:Object>(manager:Manager<T>, idxName:String, parentId:Dynamic, start:Int, limit:Int, cb:NodeErr->Array<Dynamic>->Void){
        redis.Manager.db.zrevrange('${manager.tableName}:${idxName}:${parentId}', start, start+limit-1, cb);
    }

    public static function browse<T:Object, C:Object>(manager:Manager<T>, idxName:String, parentId:Dynamic, childManager:Manager<C>, start:Int, limit:Int, cb){
        browseIds(manager, idxName, parentId, start, limit, function(err, ids){
            if (err != null || ids == null)
                return cb(err, null);
            return childManager.fetchMany(ids, cb);
        });
    }

    public static function browseReverse<T:Object, C:Object>(manager:Manager<T>, idxName:String, parentId:Dynamic, childManager:Manager<C>, start:Int, limit:Int, cb){
        browseIdsReverse(manager, idxName, parentId, start, limit, function(err:NodeErr, ids:Array<Dynamic>){
            if (err != null || ids == null)
                return cb(err, null);
            return childManager.fetchMany(ids, cb);
        });
    }
}
