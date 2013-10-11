/*
  Author: Laurent Bedubourg <lbedubourg@gmail.com>
 */
package redis;

import haxe.macro.Expr;
#if macro
import haxe.macro.Context;
#end

//TODO: keep track of database state
//TODO: do not send non modified fields to redis (beware of initial insert)
//TODO: delete nullified keys
class Macro {
    /*
      This macro do two things on RedisObject classes:

      1. Adds type metadata to each field.
      2. Instantiate a static 'manager' for the class.

    */
    macro public static function build() : Array<Field> {
        var pos = haxe.macro.Context.currentPos();
        var fields = haxe.macro.Context.getBuildFields();
        for (f in fields){
            if (Lambda.has(f.access, AStatic))
                continue;
            switch (f.kind){
                case FVar(p, _):
                    switch (p){
                        case TPath(info):
                            if (info.name == "Null"){
                                f.meta.push({
                                    pos:f.pos,
                                        params:[{ expr:EConst(CString(info.name)), pos:f.pos }],
                                        name:"nullable"
                                        });
                                switch (info.params[0]){
                                    case TPType(ppath):
                                        switch (ppath){
                                            case TPath(info):
                                                f.meta.push({
                                                    pos:f.pos,
                                                        params:[{ expr:EConst(CString(info.name)), pos:f.pos }],
                                                        name:"type"
                                                        });
                                            default:
                                        }
                                    default:
                                }
                            }
                            else {
                                f.meta.push({
                                    pos:f.pos,
                                        params:[{ expr:EConst(CString(info.name)), pos:f.pos }],
                                        name:"type"
                                        });
                            }

                        default:
                    }
                default:
            }
        }
        // create a manager for this class, ugly, unreadable, unmaintainable code taken from from sys.db.…
        var inst = Context.getLocalClass().get();
        var p = inst.pos;
        var tinst = TPath({ pack:inst.pack, name:inst.name, sub:null, params:[]});
        var path = inst.pack.copy().concat([inst.name]).join(".");
        // new RedisObjectMacro<T>(tinst)
        var enew = {
            expr:ENew({ pack:["redis"], name:"Manager", sub:null, params:[TPType(tinst)] }, [Context.parse(path, p)]),
            pos : p
        };
        // T.manager = $enew
        fields.push({ name : "manager", meta : [], kind : FVar(null,enew), doc : null, access : [AStatic,APublic], pos : p });
        return fields;
    }

    /*
      Fill target object with data.

      Data taken from Redis is of type String, we use the type meta data to fill target with expected type.


      Specials:

      @skip fields with @skip are ignored, or starting with _ are ignored too
      if the field name is not found in data, @alias("an_alias")

     */
    inline public static function fillObject<T>(target:T, data:Dynamic){
        var cls = Type.getClass(target);
        var fields = haxe.rtti.Meta.getFields(cls);
        for (f in Reflect.fields(fields)){
            var meta = Reflect.field(fields, f);
            if (Reflect.hasField(meta, "skip") || f.charAt(0) == "_"){
                continue;
            }
            var current : Dynamic = Reflect.field(data, f);
            if (current == null && meta.alias != null && meta.alias[0] != null)
                current = Reflect.field(data, meta.alias[0]);
            if (current == "__null__")
                current = null;
            else if (current == "\"__null__\"")
                current = "__null__";
            if (meta.type == null)
                continue;
            var currentType = Type.typeof(current);
            var newValue : Dynamic = switch (meta.type[0]){
                case "Int":
                switch (currentType){
                    case TNull: (meta.nullable != null) ? null : 0;
                    case TInt: current;
                    case TFloat: Std.int(current);
                    default: Std.parseInt(Std.string(current));
                }
                case "Float": switch (currentType){
                    case TNull: (meta.nullable != null) ? null : 0.0;
                    case TFloat: current;
                    case TInt: current * 1.0;
                    default: Std.parseFloat(Std.string(current));
                }
                case "Bool": switch (currentType){
                    case TNull: (meta.nullable != null) ? null : false;
                    case TInt: current > 0;
                    case TFloat: current > 0.0;
                    case TBool: current;
                    case TClass(aClass):
                        if (aClass == String){
                            var lc = (cast current).toLowerCase();
                            (lc == "t" || lc == "true" || lc == "1");
                        }
                        else {
                            (current != null);
                        }
                    default: current != null;
                }
                case "String": switch (currentType){
                    case TNull: null;
                    default: Std.string(current);
                }
                case "Date": switch (currentType){
                    case TNull: null;
                    case TFloat: Date.fromTime(current);
                    case TInt: Date.fromTime(current);
                    default:
                    var str = Std.string(current);
                    try {
                        Date.fromString(str);
                    }
                    catch(e:Dynamic){
                        var r = ~/^(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})\./;
                        if (r.match(str)){
                            Date.fromString('${r.matched(1)} ${r.matched(2)}');
                        }
                        else {
                            trace("Not matching");
                            throw e;
                        }
                    }
                }
                case "Null":
                    throw "Unsupported database value "+meta.type[0];
                default:
                    throw "Unsupported database value "+meta.type[0];
            }
            Reflect.setField(target, f, newValue);
        }
    }

    inline public static function toObject<T>(o:T, ?fieldsToUpdate:Array<String>) : Dynamic {
        var result = {};
        var cls = Type.getClass(o);
        var fields = haxe.rtti.Meta.getFields(cls);
        if (fieldsToUpdate == null)
            fieldsToUpdate = Reflect.fields(fields);
        for (f in fieldsToUpdate){
            var meta = Reflect.field(fields, f);
            if (Reflect.hasField(meta, "skip") || meta.type == null || f.charAt(0) == "_"){
                continue;
            }
            var value : Dynamic = Reflect.field(o, f);
            switch (meta.type[0]){
                case "Date":
                    value = if (value != null) DateTools.format(value, "%Y-%m-%d %H:%M:%S") else null;
            }
            // escape funny little things
            if (value == "__null__")
                value = "\"__null__\"";
            if (value == null){
                // to gain some place we really should delete the key…
                value = "__null__";
            }
            Reflect.setField(result, f, value);
        }
        return result;
    }

}
