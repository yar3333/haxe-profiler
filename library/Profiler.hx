import profiler.Gistogram;
import profiler.Instance;
import profiler.Result;
import profiler.TimeToString;
using Lambda;
using StringTools;

@:expose
class Profiler
{
	public static var instance = new Instance(1000000);
	
    public static function begin(name:String, ?subname:String) : Void
	{
		instance.begin(name, subname);
	}
    
	public static function end() : Void
	{
		instance.end();
	}
	
	
	public static function measure(name:String, ?subname:String, f:Void->Void) : Void
	{
		instance.begin(name, subname);
		try
		{
			f();
		}
		catch (e:Dynamic)
		{
			instance.end();
			rethrowException(e);
		}
		instance.end();
	}
	
	public static function measureResult<T>(name:String, ?subname:String, f:Void->T) : T
	{
		instance.begin(name, subname);
		var r : T = null;
		try
		{
			r = f();
		}
		catch (e:Dynamic)
		{
			instance.end();
			rethrowException(e);
		}
		instance.end();
		return r;
	}
	
	public static function traceResults(traceNested=false, traceCallStack=false, width=120) : Void
	{
		instance.traceResults(traceNested, traceCallStack, width);
	}
	
	public static function getNestedResults() : Array<Result>
	{
		return instance.getNestedResults();
	}
	
	public static function getSummaryResults() : Array<Result>
	{
		return instance.getSummaryResults();
	}
	
	public static function getCallStackResults(minDT=0.0, ?filterTo:String, ?filterFrom:String) : Array<Result>
	{
		return instance.getCallStackResults(minDT, filterTo, filterFrom);
	}
	
	public static function getCallStackResultsAsText(minDT=0.0, ?filterTo:String, ?filterFrom:String) : String
	{
		var results = instance.getCallStackResults(minDT, filterTo, filterFrom);
		
		var maxNameLen = 0;
		for (result in results)
		{
			if (result.name.length > maxNameLen)
			{
				maxNameLen = result.name.length;
			}
		}
		
		return results.map(function(e) return TimeToString.run(e.dt).lpad("0", 4) + " | " + e.name.rpad(" ", maxNameLen - e.name.length)).join("\n");
	}
	
	public static function getCallStack(minDt=0.0) : Dynamic
	{
		return instance.getCallStack(minDt);
	}
	
	public static function getSummaryGistogram(width=120) : String
	{
		return Gistogram.generate(getSummaryResults(), width);
	}
	
	public static function getNestedGistogram(width=120) : String
	{
		return Gistogram.generate(getNestedResults(), width);
	}
	
	public static function getCallStackGistogram(width=120) : String
	{
		return Gistogram.generate(getCallStackResults(), width);
	}
	
	public static function reset() : Void
	{
		instance.reset();
	}
	
	static inline function rethrowException(e:Dynamic) : Void
	{
		#if stdlib
			stdlib.Exception.rethrow(e);
		#else
			#if neko
			neko.Lib.rethrow(e);
			#else
			throw e;
			#end
		#end
	}
	
	#if macro
	
	/**
	 * Build macro to attach measureResult() to all methods of the class.
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
	
	static function build(profileAllMethods:Bool) : Array<haxe.macro.Expr.Field>
	{
		var printer = new haxe.macro.Printer("    ");
		
		var clas = haxe.macro.Context.getLocalClass().get();
		var fields : Array<haxe.macro.Expr.Field> = haxe.macro.Context.getBuildFields();
		
		for (field in fields)
		{
			if (!field.name.startsWith("set_")
			 && (profileAllMethods || Lambda.exists(field.meta, function(e) return e.name == ":profile"))
			 && !Lambda.exists(field.meta, function(e) return e.name == ":noprofile")
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
							f.expr = macro { return untyped Profiler.measureResult($v{name}, function() : $t ${f.expr} ); };
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
