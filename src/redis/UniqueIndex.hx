/*
  Author: Laurent Bedubourg <lbedubourg@gmail.com>
 */
package redis;

import js.Node;
import js.node.redis.Redis;
import promhx.*;

// value -> id
class UniqueIndex {
    public static function insertIfNotExists<T>(manager:Manager<T>, idxName:String, value:Dynamic, id:Dynamic) : Promise<Int> {
        if (value == null || id == null)
            return Promise.promise(0);
        return Manager.pdb.hsetnx(manager.tableName+":"+idxName, value, id);
    }

    public static function insert<T>(manager:Manager<T>, idxName:String, value:Dynamic, id:Dynamic) : Promise<Int> {
        if (value == null || id == null)
			return Promise.promise(0);
        return Manager.pdb.hset(manager.tableName+":"+idxName, value, id);
    }

    public static function delete<T>(manager:Manager<T>, idxName:String, value:Dynamic) : Promise<Int> {
        return Manager.pdb.hdel(manager.tableName+":"+idxName, value);
    }

    public inline static function get<T>(manager:Manager<T>, idxName:String, value:Dynamic) : Promise<T> {
        return getId(manager, idxName, value)
			.pipe(manager.get);
    }

    public inline static function getId<T>(manager:Manager<T>, idxName:String, value:Dynamic) : Promise<Dynamic> {
        return Manager.pdb.hget(manager.tableName+":"+idxName, value);
    }
}
