package profiler;

class TimeToString
{
	public static function run(dt:Float) : String
	{
		return Std.string(Math.round(dt * 1000));
	}
}