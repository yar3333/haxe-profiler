using Lambda;
using StringTools;

private typedef Block =
{
    var count : Int;
    var dt : Float;
}

private typedef Opened =
{
    var name : String;
    var time : Float;
}

private typedef Result =
{
    var name : String;
    var dt : Float;
    var count: Int;
}

private typedef Call =
{
	var name : String;
	var subname : String;
	var stack : Array<Call>;
	var parent : Call;
	var dt : Float;
}

class ProfilerInstance
{
    public var level(default, null) : Int;
	
	var blocks : Map<String,Block>;
    var opened : Array<Opened>;
	var call : Call;

    public function new(level:Int)
    {
        this.level = level;
		reset();
    }
    
    public function begin(name:String, ?subname:String) : Void
    {
        if (level > 0)
		{
			if (level > 1)
			{
				var subcall : Call = { name:name, subname:subname, stack:[], parent:call, dt:0 };
				call.stack.push(subcall);
				call = subcall;
			}
			
			if (opened.length > 0)
			{
				name = opened[opened.length - 1].name + '-' + name;
			}
			#if sys
			opened.push({ name:name, time:Sys.time() });
			#else
			opened.push({ name:name, time:Date.now().getTime() / 1000 });
			#end
		}
    }

    public function end() : Void
    {
        if (level > 0)
		{
			if (opened.length == 0)
			{
				throw "Profiler.end() called but there are no open blocks.";
			}
			
			var b = opened.pop();
			#if sys
			var dt = Sys.time() - b.time;
			#else
			var dt = Date.now().getTime() / 1000 - b.time;
			#end
			
			if (!blocks.exists(b.name))
			{
				blocks.set(b.name, { count:1, dt:dt });
			}
			else
			{
				blocks.get(b.name).count++;
				blocks.get(b.name).dt += dt;
			}
			
			if (level > 1)
			{
				call.dt = dt;
				call = call.parent;
			}
        }
    }
	
	public function measure(name:String, ?subname:String, f:Void->Void) : Void
	{
		begin(name, subname);
		try
		{
			f();
		}
		catch (e:Dynamic)
		{
			end();
			Exception.rethrow(e);
		}
		end();
	}
	
	public function measureResult<T>(name:String, ?subname:String, f:Void->T) : T
	{
		begin(name, subname);
		var r : T = null;
		try
		{
			r = f();
		}
		catch (e:Dynamic)
		{
			end();
			Exception.rethrow(e);
		}
		end();
		return r;
	}

    public function traceResults(width=120) : Void
    {
   		if (level > 0)
		{
			if (opened.length > 0)
			{
				for (b in opened)
				{
					trace("PROFILER WARNING: Block '" + b.name + "' not ended");
				}
			}
			
	        trace("PROFILER Summary:\n" + getGistogram(getSummaryResults(), width));
			
			trace("PROFILER Nested:\n" + getGistogram(getNestedResults(), width));
			
			if (level > 1)
			{
				trace("PROFILER Calls:\n" + getGistogram(getCallStackResults(), width));
			}
        }
    }
	
	public function getNestedResults() : Array<Result>
	{
        if (level < 1) return [];
		
		var r = [];
        for (name in blocks.keys()) 
        {
            var block = blocks.get(name);
            r.push( {
                 name: name
                ,dt: block.dt
                ,count: block.count
            });
        }
        
        r.sort(function(a, b)
        {
            var ai = a.name.split('-');
            var bi = b.name.split('-');
            
            for (i in 0...Std.int(Math.min(ai.length, bi.length)))
            {
                if (ai[i] != bi[i])
                {
                    return ai[i] < bi[i] ? -1 : 1;
                }
            }
            
            return Std.int((b.dt - a.dt) * 1000);
        });
		
		return r;
	}
    
    public function getSummaryResults() : Array<Result>
    {
        if (level < 1) return [];
		
		var results = new Map<String,Result>();
		
        for (name in blocks.keys()) 
        {
            var block = blocks.get(name);
            var nameParts = name.split('-');
            name = nameParts[nameParts.length - 1];
            if (!results.exists(name))
            {
                results.set(name, { name:name, dt:0.0, count:0 });
            }
            results.get(name).dt += block.dt;
            results.get(name).count += block.count;
        }
        
        var values = Lambda.array(results);
        values.sort(function(a, b)
        {
            return Std.int((b.dt - a.dt) * 1000);
        });
		
		return values;
    }
	
	public function getCallStackResults(minDT=0.0, ?filter:String) : Array<Result>
	{
		return level > 1 ? callStackToResults(minDT, call, 0, filter) : [];
	}
	
	public function getCallStackResultsAsText(minDT=0.0, ?filter:String) : String
	{
		var results = getCallStackResults(minDT, filter);
		
		var maxNameLen = 0; for (result in results) maxNameLen = Std.max(maxNameLen, result.name.length);
		
		return results.map(function(e)
		{
			return dtAsStr(e.dt).lpad("0", 4) + " | " + e.name.rpad(" ", maxNameLen - e.name.length);
		}
		).join("\n");
	}
	
	public function getCallStack(minDt=0.0) : Dynamic
	{
		return cloneCall(call, minDt).stack;
	}
    
    public function getGistogram(results:Iterable<Result>, width:Int) : String
    {
		var maxLen = 0;
		var maxDT = 0.0;
		var maxCount = 0;
		for (result in results) 
		{
			maxLen = Std.int(Math.max(maxLen, result.name.length));
			maxDT = Math.max(maxDT, result.dt);
			maxCount = Std.int(Math.max(maxCount, result.count));
		}
		
		var countLen = maxCount > 1 ? Std.string(maxCount).length : 0;
		
		var maxW = Std.max(1, width - maxLen - countLen);
		
		var r = "";
		for (result in results)
		{
			
			r += StringTools.lpad(dtAsStr(result.dt), "0", dtAsStr(maxDT).length) + " | ";
			r += StringTools.rpad(StringTools.rpad('', '*', Math.round(result.dt / maxDT * maxW)), ' ', maxW) + " | ";
			r += StringTools.rpad(result.name, " ", maxLen);
			if (countLen > 0)
			{
				r += " [" + StringTools.rpad(Std.string(result.count), " ", countLen) + " time(s)]";
			}
			r += "\n";
		}
		return r;
    }
	
	public function reset() : Void
	{
		if (level > 0)
		{
			blocks = new Map<String,Block>();
			opened = [];
			if (level > 1)
			{
				call = { name:"", subname:null, stack:[], parent:null, dt:null };
			}
		}
	}
	
	function cloneCall(c:Call, minDt:Float) : Dynamic
	{
		var dt = c.dt != null ? dtAsStr(c.dt).lpad(" ", 4) : "";
		var name = dt + " " + c.name + (c.subname != null ? " / " + c.subname : "");
		var stack = c.stack != null ? c.stack.filter(function(e) return Math.round(e.dt * 1000) >= minDt) : [];
		if (stack.length > 0)
		{
			return 
			{
				name: name,
				stack: stack.map(function(e) return cloneCall(e, minDt))
			}
		}
		return name;
	}
	
	function callStackToResults(minDT:Float, call:Call, indent:Int, ?filter:String) : Array<Result>
	{
		var r = [];
		for (c in call.stack)
		{
			if ((c.dt == null || c.dt >= minDT) && callStackHasName(c, filter))
			{
				var prefix = ""; for (i in 0...indent) prefix += "  ";
				r.push( { name:prefix + c.name + (c.subname != null ? " / " + c.subname : ""), dt:c.dt, count:1  } );
				r = r.concat(callStackToResults(minDT, c, indent + 2, filter));
			}
		}
		return r;
	}
	
	function callStackHasName(call:Call, filter:String) : Bool
	{
		if (filter == null || filter == "") return true;
		if (call.name + (call.subname != null ? " / " + call.subname : "") == filter) return true;
		for (c in call.stack) if (callStackHasName(c, filter)) return true;
		return false;
	}
	
	function dtAsStr(dt:Float) : String
	{
		return Std.string(Std.int(dt * 1000));
	}
}

class Profiler
{
	public static var instance = new ProfilerInstance(1000000);
	
    public static function begin(name:String, ?subname:String) : Void
	{
		instance.begin(name, subname);
	}
    
	public static function end() : Void
	{
		instance.end();
	}
	
	public function measure(name:String, ?subname:String, f:Void->Void) : Void
	{
		instance.measure(name, subname, f);
	}
	
	public function measureResult<T>(name:String, ?subname:String, f:Void->T) : T
	{
		return instance.measureResult(name, subname, f);
	}
	
	public function traceResults(width=120) : Void
	{
		instance.traceResults(width);
	}
	
	public function getNestedResults() : Array<Result>
	{
		return instance.getNestedResults();
	}
	
	public function getSummaryResults() : Array<Result>
	{
		return instance.getSummaryResults();
	}
	
	public function getCallStackResults(minDT = 0.0, ?filter:String) : Array<Result>
	{
		return instance.getCallStackResults(minDT, filter);
	}
	
	public function getCallStackResultsAsText(minDT=0.0, ?filter:String) : String
	{
		return instance.getCallStackResultsAsText(minDT, filter);
	}
	
	public function getCallStack(minDt=0.0) : Dynamic
	{
		return instance.getCallStack(minDt);
	}
	
	public function getGistogram(results:Iterable<Result>, width:Int) : String
	{
		return instance.getGistogram(results, width);
	}
	
	public function reset() : Void
	{
		instance.reset();
	}
	
	#if macro
	
	/**
	 * Build macro to attach measureResult() to methods marked as @profile.
	 * You can exclude some methods by @:noprofile meta.
	 */
	public static macro function buildAll() : Array<haxe.macro.Expr.Field>
	{
		return build(true);
	}
	
	/**
	 * Build macro to attach measureResult() to methods marked as @:profile.
	 */
	public static macro function buildMarked() : Array<haxe.macro.Expr.Field>
	{
		return build(false);
	}
	
	static macro function build(profileAllMethods:Bool) : Array<haxe.macro.Expr.Field>
	{
		var printer = new haxe.macro.Printer("    ");
		
		var clas = haxe.macro.Context.getLocalClass().get();
		var fields : Array<haxe.macro.Expr.Field> = haxe.macro.Context.getBuildFields();
		
		for (field in fields)
		{
			if (!field.name.startsWith("set_")
			 && (profileAllMethods || Lambda.exists(field.meta, function(e) return e.name == "profile"))
			 && !Lambda.exists(field.meta, function(e) return e.name == "noprofile")
			) {
				switch (field.kind)
				{
					case haxe.macro.Expr.FieldType.FFun(f):
						var name = clas.pack.join(".");
						if (name.length > 0) name += ".";
						name += clas.name + "." + field.name;
						
						if (isVoid(f.ret))
						{
							f.expr = macro { Profiler.measure($v{name}, function() : Void ${f.expr} ); };
						}
						else
						{
							var t = f.ret;
							f.expr = macro { return Profiler.measureResult($v{name}, function() : $t ${f.expr} ); };
						}
						
					default:
				}
			}
		}
		
		return fields;
	}
	
	static function isVoid(t:Null<haxe.macro.Expr.ComplexType>) : Bool
	{
		if (t != null)
		{
			switch (t)
			{
				case haxe.macro.Expr.ComplexType.TPath(p):
					return p.name == "Void" && p.pack.length == 0 && p.sub == null
						|| p.name == "StdTypes" && p.pack.length == 0 && p.sub == "Void";
				default:
			}
		}
		return false;
	}
	
	#end
}
