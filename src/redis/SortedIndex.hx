/*
  Author: Laurent Bedubourg <lbedubourg@gmail.com>
 */
package redis;

import js.Node;
import js.node.redis.Redis;
import promhx.*;


// sort(value) -> id
class SortedIndex {
    inline public static function delete<T>(manager:Manager<T>, idxName:String, id:Dynamic){
		return Manager.pdb.zrem(manager.tableName+":"+idxName, id);
    }

    inline public static function insert<T>(manager:Manager<T>, idxName:String, id:Dynamic, value:Int){
        if (value == null || id == null)
            return Promise.promise(0);
        return Manager.pdb.zadd(manager.tableName+":"+idxName, value, id);
    }

    inline public static function browseIds<T>(manager:Manager<T>, idxName:String, start:Int, limit:Int){
        return Manager.pdb.zrange(manager.tableName+":"+idxName, start, start+limit-1);
    }

    inline public static function browseIdsReverse<T>(manager:Manager<T>, idxName:String, start:Int, limit:Int){
		return Manager.pdb.zrevrange(manager.tableName+":"+idxName, start, start+limit-1);
    }

    inline public static function count<T>(manager:Manager<T>, idxName:String){
		return Manager.pdb.zcard(manager.tableName+":"+idxName);
    }

    inline public static function browse<T:Object>(manager:Manager<T>, idxName:String, start:Int, limit:Int){
		return browseIds(manager, idxName, start, limit).pipe(manager.fetchMany);
    }

    inline public static function browseReverse<T:Object>(manager:Manager<T>, idxName:String, start:Int, limit:Int){
		return browseIdsReverse(manager, idxName, start, limit).pipe(manager.fetchMany);
    }
}
