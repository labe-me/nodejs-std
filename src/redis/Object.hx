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

    public function insert(?cb:NodeErr->Void){
        untyped _manager.insert(this, cb);
    }

    public function update(?cb:NodeErr->Void){
        untyped _manager.update(this, cb);
    }

    public function delete(?cb:NodeErr->Int->Void){
        untyped _manager.delete(this, cb);
    }

    #if promhx
    public inline function pinsert<T>(){
        var p = new promhx.Promise<T>();
        insert(function(err){
            if (err != null) p.reject(err) else p.resolve(cast this);
        });
        return p;
    }
    public inline function pupdate<T>(){
        var p = new promhx.Promise<T>();
        update(function(err){
            if (err != null) p.reject(err) else p.resolve(cast this);
        });
        return p;
    }
    public inline function pdelete<T>(){
        var p = new promhx.Promise<T>();
        delete(function(err, v){
            if (err != null) p.reject(err) else p.resolve(v == 0 ? null : cast this);
        });
        return p;
    }
    #end
}
