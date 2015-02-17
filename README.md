# profiler haxe library #

This library help you to profile the code.

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