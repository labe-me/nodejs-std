/*
  Author: Laurent Bedubourg <lbedubourg@gmail.com>
 */
package redis;
import js.Node;
import js.node.redis.*;

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

    public function deleteIndexes(next:NodeErr->Void){
        next(null);
    }

    public function updateIndexes(next:NodeErr->Void){
        next(null);
    }

    public function insert(?cb){
        untyped _manager.insert(this, cb);
    }

    public function update(?cb){
        untyped _manager.update(this, cb);
    }

    public function delete(?cb){
        untyped _manager.delete(this, cb);
    }
}