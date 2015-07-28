package profiler;

class Gistogram
{
    public static function generate(results:Iterable<Result>, width:Int) : String
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
		
		var maxW = width - maxLen - countLen;
		if (maxW < 1) maxW = 1;
		
		var r = "";
		for (result in results)
		{
			
			r += StringTools.lpad(TimeToString.run(result.dt), "0", TimeToString.run(maxDT).length) + " | ";
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
}