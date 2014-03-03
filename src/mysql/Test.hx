package mysql;

import bdd.reporter.*;
import promhx.*;
import promhx.mdo.*;
import mysql.Mysql;

class Suite extends bdd.ExampleGroup {
	public inline function asyncStart(?timeout:Int){
		return cast createAsyncBlock(function(?data){}, timeout);
	}
}




class Test extends Suite {

	public function example(){
		describe("Mysql", function(){
			it("Can connect", function(){
				var done = asyncStart();
				var cx = new Connection(null, { user:"root", password:"", database:"test" });
				cx.connect().pipe(function(_){
					return cx.end();
				}).then(function(_){
					should.be.True(true);
					done();
				});
			});
			it("Can select", function(){
				var done = asyncStart();
				var cx = new Connection(null, { user:"root", password:"", database:"test" });
				cx.connect().pipe(function(_){
					return cx.query("SELECT 1 as a").then(function(res){
						should.be.equal(res.length, 1);
						should.be.equal(res[0].a, 1);						
						return true;
					});
				}).pipe(function(_){
					return cx.end();
				}).then(function(_){
					should.be.True(true);
					done();
				});
			});
			it("Can start transaction", function(){
				var done = asyncStart();
				var cx = new Connection({ user:"root", password:"", database:"test"});
				PromiseM.dO({
					cx.connect();
					cx.query("DROP TABLE IF EXISTS DataTest");
					
					cx.query("CREATE TABLE DataTest (id INT PRIMARY KEY AUTO_INCREMENT, data TINYTEXT)");
					cx.beginTransaction();
					cx.query("INSERT INTO DataTest SET ?", {data:"Sample text"});
					cx.commit();					
				}).then(function(_){
					cx.end();
					should.be.True(true);
					done();
				}).catchError(function(err){
					should.be.False(true);
					trace(err);
					cx.rollback().pipe(function(_) return cx.end());
				});
			});
			it("Can stream results", function(){
				var done = asyncStart();
				var cx = new Connection({ user:"root", password:"", database:"test"});
				PromiseM.dO({
					cx.connect();
					cx.query("DROP TABLE IF EXISTS DataTest");
					
					cx.query("CREATE TABLE DataTest (id INT PRIMARY KEY AUTO_INCREMENT, data TINYTEXT)");
					cx.beginTransaction();
					cx.query("INSERT INTO DataTest SET ?", {data:"1 Sample text"});
					cx.query("INSERT INTO DataTest SET ?", {data:"2 Sample text"});
					cx.query("INSERT INTO DataTest SET ?", {data:"3 Sample text"});
					{
						var id = 1;
						var stream = cx.stream("SELECT * FROM DataTest");
						stream.then(function(part){
							should.be.equal(part.row.id, id++);
						}).endThen(function(_){
							return null;
						});
					}
					cx.commit();		
				}).then(function(_){
					cx.end();
					should.be.True(true);
					done();
				}).catchError(function(err){
					should.be.False(true);
					trace(err);
					cx.rollback().pipe(function(_) return cx.end());
				});
				
			});
		});
		
	}
	
	public static function main(){
		var reporters = new Map<String, Array<Class<bdd.reporter.helper.Abstract>>>();
        reporters.set('desc', [Descriptive, Error, Summary]);
        reporters.set('dot', [Dot, Error, Summary]);
        reporters.set('silent', [Silent]);
		reporters.set('default', reporters.get('desc'));
        new bdd.reporter.helper.Factory().createFromList(reporters.get('default'));
        var runner = new bdd.Runner();
		runner.add(Test);
        runner.run();
	}
}