/*
  Author: Laurent Bedubourg <lbedubourg@gmail.com>
 */
package redis;

import js.Node;
import js.node.redis.Redis;
import promhx.*;


// parent -> children*
class HasManyRelation {
    public static function insert<T>(manager:Manager<T>, idxName:String, parentId:Dynamic, childId:Dynamic, ?sortValue:Int){
		if (parentId == null || childId == null)
			return Promise.promise(0);
		return Manager.pdb.zadd('${manager.tableName}:${idxName}:${parentId}', sortValue != null ? cast sortValue : childId, childId);
    }

    public static function delete<T>(manager:Manager<T>, idxName:String, parentId:Dynamic, childId:Dynamic){
		return Manager.pdb.del('${manager.tableName}:${idxName}:${parentId}');
    }

    public static function parentDestroyed<T>(manager:Manager<T>, idxName:String, parentId:Dynamic){
		return Manager.pdb.del('${manager.tableName}:${idxName}:${parentId}');
    }

    public static function count<T>(manager:Manager<T>, idxName:String, parentId:Dynamic){
		return Manager.pdb.zcard('${manager.tableName}:${idxName}:${parentId}');
    }

    public static function browseIds<T>(manager:Manager<T>, idxName:String, parentId:Dynamic, start:Int, limit:Int) : Promise<Array<Dynamic>> {
		return Manager.pdb.zrange('${manager.tableName}:${idxName}:${parentId}', start, start+limit-1);
    }

    public static function score<T>(manager:Manager<T>, idxName:String, parentId:Dynamic, childId:Dynamic) : Promise<Float> {
        return Manager.pdb.zscore('${manager.tableName}:${idxName}:${parentId}', childId).then(function(v) return Std.parseFloat(v));
    }

    public static function browseIdsReverse<T:Object>(manager:Manager<T>, idxName:String, parentId:Dynamic, start:Int, limit:Int){
		return Manager.pdb.zrevrange('${manager.tableName}:${idxName}:${parentId}', start, start+limit-1);
    }

	// TODO: stream
    public static function browse<T:Object, C:Object>(manager:Manager<T>, idxName:String, parentId:Dynamic, childManager:Manager<C>, start:Int, limit:Int) : Promise<Array<C>> {
        return browseIds(manager, idxName, parentId, start, limit)
			.pipe(childManager.fetchMany);
    }

    public static function browseReverse<T:Object, C:Object>(manager:Manager<T>, idxName:String, parentId:Dynamic, childManager:Manager<C>, start:Int, limit:Int) : Promise<Array<C>> {
		return browseIdsReverse(manager, idxName, parentId, start, limit).pipe(childManager.fetchMany);
    }
}
