# profiler haxe library #

This library help you to profile the code.

#### Manual collect data ####
```
#!haxe
var profiler = new Profiler(5); // 5 = collect data deep level

profiler.measure("myCodeA", function()
{
    // code to measure duration
});

var result = profiler.measureResult("myCodeB", function()
{
    // code to measure duration
    return "abc"; // result
});
```

#### Collect data by macro ####
Use **@:build(Profiler.build(full_path_to_static_profiler_var))** to enable profiling for classes and **@ profile** (without space) before class/method to specify profiling all/specified class methods:
```
#!haxe
class Main
{
    public static var profiler = new stdlib.Profiler();
    
    static function main()
    {
        var obj = new MyClassToProfile();
        obj.f();
    }
}

@:build(Profiler.build(Main.profiler))
class MyClassToProfile
{
    @profile public function f() {  trace("f() called"); }
}
```

#### Getting collected data ####
```
#!haxe
// trace summary
profiler.traceResults();

// get all calls as linear array
var results = profiler.getCallStackResults();

// get all calls as tree
var callTree = profiler.getCallStack();
//it is very useful to generate human-readable json from this
trace(Json.stringify({ name:"myApp", stack:callTree }));
```
