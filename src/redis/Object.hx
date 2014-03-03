/*
  Author: Laurent Bedubourg <lbedubourg@gmail.com>
 */
package redis;
import js.Node;
import js.node.redis.*;
import promhx.*;
import promhx.mdo.*;


/*

  @expire(intSeconds)
  class MyClass extends RedisObject {
      @noAutoIncrement public var id : Int;
      public var str : String;
      public var flt : Float;
      public var date : Date;
  }

 */
@:autoBuild(redis.Macro.build())
class Object {
    @skip var _manager : Manager<Dynamic>;

    public function new(){
        if (_manager == null)
            _manager = untyped Type.getClass(this).manager;
    }

    public function fromData(obj:Dynamic) : Object {
        Macro.fillObject(this, obj);
        return this;
    }

    public function deleteIndexes() : promhx.Promise<Dynamic> {
        return promhx.Promise.promise(true);
    }

    public function updateIndexes() : promhx.Promise<Dynamic> {
        return promhx.Promise.promise(true);
    }

    public function oldInsert(?cb:NodeErr->Void){
        untyped _manager.oldInsert(this, cb);
    }

    public function oldUpdate(?fields:Array<String>, ?cb:NodeErr->Void){
        untyped _manager.oldUpdate(this, fields, cb);
    }

    public function oldDelete(?cb:NodeErr->Int->Void){
        untyped _manager.oldDelete(this, cb);
    }

    public function insert<T>() : Promise<T> {
		return (cast _manager).insert(this).then(function(_) return this);
    }
	
    public function update<T>(?fields:Array<String>) : Promise<T> {
		return (cast _manager).update(this, fields).then(function(_) return this);
    }
	
    public function delete<T>() : Promise<Bool> {
		return (cast _manager).delete(this).then(function(n) return n > 0);
    }
}
