package js.node.redis;
import js.node.redis.Redis;
import promhx.*;

class RedisPromiseWrapper {
	var client : RedisClient;

	public function new(rc:RedisClient){
		client = rc;
	}

	static function pCallback<T>(p:Promise<T>, err:Err, res:T){
		if (err != null)
			p.reject(err);
		else
			p.resolve(res);
	}

	inline static function wrap<T>(fn) : Promise<T> {
		var p = new Promise();
		fn(pCallback.bind(p));
		return p;
	}

	inline static function wrap1<T>(fn, a:Dynamic) : Promise<T> {
		var p = new Promise();
		fn(a, pCallback.bind(p));
		return p;
	}

	inline static function wrap2<T>(fn, a:Dynamic, b:Dynamic) : Promise<T> {
		var p = new Promise();
		fn(a, b, pCallback.bind(p));
		return p;
	}

	inline static function wrap3<T>(fn, a:Dynamic, b:Dynamic, c:Dynamic) : Promise<T> {
		var p = new Promise();
		fn(a, b, c, pCallback.bind(p));
		return p;
	}

	// control
	inline public function info() : Promise<Dynamic> {
		return wrap(client.info);
	}
	inline public function shutdown() : Promise<String> {
		return wrap(client.shutdown);
	}
	inline public function bgsave() : Promise<String> {
		return wrap(client.bgsave);
	}
	inline public function lastsave() : Promise<Int> {
		return wrap(client.lastsave);
	}

	// all
	inline public function exists(k:String) : Promise<Int> {
		return wrap1(client.exists, k);
	}
	inline public function del(k:String) : Promise<Int> {
		return wrap1(client.del, k);
	}
	inline public function type(k:String) : Promise<String> {
		return wrap1(client.type, k);
	}
	inline public function keys(pattern:String) : Promise<Array<Dynamic>> {
		return wrap1(client.keys, pattern);
	}
	inline public function randomkey(k:String) : Promise<String> {
		return wrap1(client.randomkey, k);
	}
	inline public function rename(k:String, nk:String) : Promise<String> {
		return wrap2(client.rename, k, nk);
	}
	inline public function renamenx(k:String, nk:String) : Promise<String> {
		return wrap2(client.renamenx, k, nk);
	}
	inline public function dbsize() : Promise<Int> {
		return wrap(client.dbsize);
	}
	inline public function expire(k:String, secs:Int) : Promise<Int> {
		return wrap2(client.expire, k, secs);
	}
	inline public function ttl(k:String) : Promise<Int> {
		return wrap1(client.ttl, k);
	}
	inline public function select(index:Int) : Promise<String> {
		return wrap1(client.select, index);
	}
	inline public function move(k:String, index:Int) : Promise<Int> {
		return wrap2(client.move, k, index);
	}
	inline public function flushdb() : Promise<String> {
		return wrap(client.flushdb);
	}
	inline public function flushall() : Promise<String> {
		return wrap(client.flushall);
	}

	// strings
	inline public function set(k:String, v:String) : Promise<Bool> { 
		return wrap2(client.set, k, v); 
	}
	inline public function get(k:String) : Promise<String> {
		return wrap1(client.get, k); 
	}
	inline public function incr(k:String) : Promise<Int> {
		return wrap1(client.incr, k); 
	}
	inline public function incrby(k:String, by:Int) : Promise<Int> {
		return wrap2(client.incrby, k, by);
	}
	inline public function decr(k:String) : Promise<Int> {
		return wrap1(client.decr, k);
	}
	inline public function decrby(k:String, by:Int) : Promise<Int> {
		return wrap2(client.decrby, k, by);
	}
	inline public function setnx(k:String, v:String) : Promise<Bool> {
		return wrap2(client.setnx, k, v);
	}
	inline public function mset(ks:Array<Dynamic>) : Promise<Bool> {
		return wrap1(client.mset, ks);
	}
	inline public function msetnx(ks:Array<Dynamic>) : Promise<Bool> {
		return wrap1(client.msetnx, ks);
	}
	inline public function mget(ks:Array<String>) : Promise<Array<String>> {
		return wrap1(client.mget, ks);
	}
	inline public function getset(k:String, v:String) : Promise<String> {
		return wrap2(client.getset, k, v); 
	}
	inline public function append(k:String, v:String) : Promise<Int> {
		return wrap2(client.append, k, v); 
	}
	inline public function substr(k:String, s:Int, e:Int) : Promise<String> {
		return wrap3(client.substr, k, s, e); 
	}
	inline public function setex(k:String, t:Int, v:Dynamic) : Promise<String> {
		return wrap3(client.setex, k, t, v); 
	}

	// lists
	inline public function lpush(k:String, v:String) : Promise<Int> {
		return wrap2(client.lpush, k, v);
	}
	inline public function rpush(k:String, v:String) : Promise<Int> {
		return wrap2(client.rpush, k, v);
	}
	inline public function llen(k:String) : Promise<Int> {
		return wrap1(client.llen, k);
	}
	inline public function lrange(k:String, s:Int, e:Int) : Promise<Array<Dynamic>> {
		return wrap3(client.lrange, k, s, e);
	}
	inline public function ltrim(k:String, s:Int, e:Int) : Promise<String> {
		return wrap3(client.ltrim, k, s, e);
	}
	inline public function lindex(l:String, i:Int) : Promise<Dynamic> {
		return wrap2(client.lindex, l, i);
	}
	inline public function lset(k:String, i:Int, v:String) : Promise<String> {
		return wrap3(client.lset, k, i, v);
	}
	inline public function lrem(k:String, c:Int, v:String) : Promise<Int> {
		return wrap3(client.lrem, k, c, v);
	}
	inline public function lpop(k:String) : Promise<String> {
		return wrap1(client.lpop, k);
	}
	inline public function rpop(k:String) : Promise<String> {
		return wrap1(client.rpop, k);
	}
	inline public function blpop(k:String, s:Int) : Promise<Array<Dynamic>> {
		return wrap2(client.blpop, k, s);
	}
	inline public function brpop(k:String, s:Int) : Promise<Array<Dynamic>> {
		return wrap2(client.brpop, k, s);
	}
	inline public function rpoplpush(sk:String, dk:String) : Promise<Dynamic> {
		return wrap2(client.rpoplpush, sk, dk);
	}

	// sets
	inline public function sadd(k:String, v:String) : Promise<Int> {
		return wrap2(client.sadd, k, v);
	}
	inline public function srem(k:String, v:String) : Promise<Int> {
		return wrap2(client.srem, k, v);
	}
	inline public function spop(k:String) : Promise<Dynamic> {
		return wrap1(client.spop, k);
	}
	inline public function smove(sk:String, dk:String, member:String) : Promise<Int> {
		return wrap3(client.smove, sk, dk, member);
	}
	inline public function scard(k:String) : Promise<Int> {
		return wrap1(client.scard, k);
	}
	inline public function sismember(k:String, m:String) : Promise<Int> {
		return wrap2(client.sismember, k, m);
	}
	inline public function sinter(k1:String, k2:String) : Promise<Array<Dynamic>> {
		return wrap2(client.sinter, k1, k2);
	}
	inline public function sinterstore(dst:String, k1:String, k2:String) : Promise<String> {
		return wrap3(client.sinterstore, dst, k1, k2);
	}
	inline public function sunion(k1:String, k2:String) : Promise<Array<Dynamic>> {
		return wrap2(client.sunion, k1, k2);
	}
	inline public function sunionstore(dst:String, k1:String, k2:String) : Promise<String> {
		return wrap3(client.sunionstore, dst, k1, k2);
	}
	inline public function sdiff(k1:String, k2:String) : Promise<Array<Dynamic>> {
		return wrap2(client.sdiff, k1, k2);
	}
	inline public function sdiffstore(dst:String, k1:String, k2:String) : Promise<String> {
		return wrap3(client.sdiffstore, dst, k1, k2);
	}
	inline public function smembers(k:String) : Promise<Array<Dynamic>> {
		return wrap1(client.smembers, k);
	}
	inline public function srandmember(k:String) : Promise<Dynamic> {
		return wrap1(client.srandmember, k);
	}

	// hash
	inline public function hset(k:String, f:String, v:String) : Promise<Int> {
		return wrap3(client.hset, k, f, v);
	}
	inline public function hget(k:String, f:String) : Promise<Dynamic> {
		return wrap2(client.hget, k, f);
	}
	inline public function hsetnx(k:String, f:String, v:String) : Promise<Int> {
		return wrap3(client.hsetnx, k, f, v);
	}

    //@:overload(function(k:String, o:Dynamic) : Promise<String> {})
	inline public function hmset(k:String, f:Array<String>) : Promise<String> {
		return wrap2(client.hmset, k, f);
	}
	// first field is key name, the remaining are hash field names
	inline public function hmget(k:Array<String>) : Promise<Array<Dynamic>> {
		return wrap1(client.hmget, k);
	}
    inline public function hincrby(k:String, f:String, v:Int) : Promise<Int> {
		return wrap3(client.hincrby, k, f, v);
	}
    inline public function hincrbyfloat(k:String, f:String, v:Float) : Promise<Int> {
		return wrap3(client.hincrbyfloat, k, f, v);
	}
	inline public function hexists(k:String, f:String) : Promise<Int> {
		return wrap2(client.hexists, k, f);
	}
	inline public function hdel(k:String, f:String) : Promise<Int> {
		return wrap2(client.hdel, k, f);
	}
	inline public function hlen(k:String) : Promise<Int> {
		return wrap1(client.hlen, k);
	}
	inline public function hkeys(k:String) : Promise<Array<Dynamic>> {
		return wrap1(client.hkeys, k);
	}
	inline public function hvals(k:String) : Promise<Array<Dynamic>> {
		return wrap1(client.hvals, k);
	}
	inline public function hgetall(k:String) : Promise<Array<Dynamic>> {
		return wrap1(client.hgetall, k);
	}

	// sorted sets
	inline public function zadd(k:String, s:Int, m:String) : Promise<Int> {
		return wrap3(client.zadd, k, s, m);
	}
	inline public function zrem(k:String, m:String) : Promise<Int> {
		return wrap2(client.zrem, k, m);
	}
	inline public function zincrby(k:String, i:Int, m:String) : Promise<Int> {
		return wrap3(client.zincrby, k, i, m);
	}
	inline public function zrank(k:String, m:String) : Promise<Dynamic> {
		return wrap2(client.zrank, k, m);
	}
	inline public function zrankrev(k:String, m:String) : Promise<Dynamic> {
		return wrap2(client.zrankrev, k, m);
	}

	// eval script with 0 keys
	inline public function eval0(script:String) : Promise<Int> {
		return wrap2((cast client).eval, script, 0);
	}

    //@:overload(function(k:String, s:Int, e:Int, opt:String) : Promise<Array<Dynamic>>{})
	inline public function zrange(k:String, s:Int, e:Int) : Promise<Array<Dynamic>> {
		return wrap3(client.zrange, k, s, e);
	}
	inline public function zrevrange(k:String, s:Int, e:Int) : Promise<Array<Dynamic>> {
		return wrap3(client.zrevrange, k, s, e);
	}
	inline public function zrangebyscore(k:String, min:Int, max:Int) : Promise<Array<Dynamic>> {
		return wrap3(client.zrangebyscore, k, min, max);
	}
	inline public function zremrangebyrank(k:String, s:Int, e:Int) : Promise<Int> {
		return wrap3(client.zremrangebyrank, k, s, e);
	}
	inline public function zremrangebyscore(k:String, min:Int, max:Int) : Promise<Int> {
		return wrap3(client.zremrangebyscore, k, min, max);
	}
	inline public function zcard(k:String) : Promise<Int> {
		return wrap1(client.zcard, k);
	}
	inline public function zscore(k:String, e:String) : Promise<Dynamic> {
		return wrap2(client.zscore, k, e);
	}
	inline public function zunionstore(prms:Array<Dynamic>) : Promise<Int> {
		return wrap1(client.zunionstore, prms);
	}
	inline public function zinterstore(prms:Array<Dynamic>) : Promise<Int> {
		return wrap1(client.zinterstore, prms);
	}
	inline public function sort(prms:Array<Dynamic>) : Promise<Array<Dynamic>> {
		return wrap1(client.sort, prms);
	}

    // publish/subscribe
    inline public function subscribe(channel:String) : Promise<Int> {
		return wrap1(client.subscribe, channel);
	}

    inline public function publish(channel:String, message:String) : Promise<Int> {
		return wrap2(client.publish, channel, message);
	}

}