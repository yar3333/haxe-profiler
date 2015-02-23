# profiler haxe library #

This library help you to profile the code.

Using example:
```
@:build(Profiler.buildAll())
class Test
{
	public function new() {}
	
	public function pubF()
	{
		Sys.sleep(1);
		privF();
		Sys.sleep(2);
	}
	
	function privF() Sys.sleep(0.5);
}

class Main
{
	static function main()
	{
		var test = new Test();
		
		test.pubF();
		test.pubF();
		
		Sys.println(Profiler.getCallStackResultsAsText());
	}
}
```

Result:
```
0000 | Test.new
3503 | Test.pubF
0500 |     Test.privF
3501 | Test.pubF
0500 |     Test.privF
```

## Manual collect data ##

Profiler has two alternative: direct call begin/end or measure with a callback function.

### Direct call begin/end
```
#!haxe
Profiler.begin("myCodeA");
// code to measure duration
Profiler.end();
```

### Measure with a callback function
```
#!haxe
Profiler.measure("myCodeA", function()
{
    // code to measure duration
});

var result = Profiler.measureResult("myCodeB", function()
{
    // code to measure duration
    return "abc"; // result
});
```


## Collect data by macro ##

Use `@:build(Profiler.buildAll())` to profile all methods of class. Use `@:noprofile` to exclude methods.

Use `@:build(Profiler.buildMarked())` to profile only methods with a `@:profile` meta.
```
#!haxe
@:build(Profiler.buildMarked())
class MyClassToProfile
{
    @:profile public function f() {  trace("f() called"); }
}
```

## Getting collected data ##
```
#!haxe
// trace summary
Profiler.traceResults();

// get all calls as linear array
var results = Profiler.getCallStackResults();

// get all calls as tree
var callTree = Profiler.getCallStack();
// it is very useful to generate human-readable json from this
trace(Json.stringify({ name:"myApp", stack:callTree }));
```