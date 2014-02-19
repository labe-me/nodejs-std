A little library wrote to make my nodejs + redis life more acceptable.

That's a little bit hacky, promhx was introduced at a later stage and the library could be improved but it works.

Here's a little untested example of basic features.

    import promhx.*;
	import promhx.mdo.*;
	
    class Todo extends redis.Object {
        public var id : Int;
        public var date : Date;
        public var title : String;
		public var done = false;

        public function new(aTitle){
			super();
			date = Date.now();
			title = aTitle;
		}
    }

	var t = new Todo("Do something great");	
	t.insert().pipe(function(_){
		return Todo.manager.get(t.id).pipe(function(todo){
			// there's no app cache right now, todo != t for the same id
			todo.done = true;
			return todo.update();
		}).pipe(function(todo){
			return todo.delete();
		});
	});

	Todo.manager.each(function(todo){
		if (todo.done)
			return todo.delete();
		return Promise.promise(null);
	});

	Todo.manager.count().then(function(n){
		Todo.manager.each(start, limit, function(item){
			item.date = Date.now();
			return item.update();
		});
	});

The library contains some Index manipulation methods:

	redis.UniqueIndex
	redis.SortedIndex
	redis.HasManyRelation

You can override the redis.Object.updateIndexes() and redis.Object.deleteIndexes() method to update your indexes.

For instance:

	class User extends redis.Object {
		...

        override function deleteIndexes(){
			return PromiseM.dO({
				UniqueIndex.delete(manager, "_pseudoIndex", pseudo == null ? null : pseudo.toLowerCase());
				UniqueIndex.delete(manager, "_emailIndex", email);
			});
		}

        override function updateIndexes(){
            return PromiseM.dO({
                UniqueIndex.insert(manager, "_pseudoIndex", pseudo == null ? null : pseudo.toLowerCase(), id);
                UniqueIndex.insert(manager, "_emailIndex", email, id);
            });
        }
	}

This is only index manipulation, it won't prevent your logic to fuckup the database inserting two users with the same email (the unique index will only point to the latest).

Macros could automate indexes management.



