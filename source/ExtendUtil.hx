import flixel.FlxG;
import flixel.FlxObject;

class ExtendUtil {
	public inline static function last<T>(array:Array<T>):T {
		return array[array.length - 1];
	}

	public inline static function first<T>(array:Array<T>):T {
		return array[0];
	}

	public static inline function screenCenterX(spr:FlxObject):FlxObject
	{
		spr.x = (FlxG.width - spr.width) / 2;

		return spr;
	}

	public static inline function screenCenterY(spr:FlxObject):FlxObject
	{
		spr.y = (FlxG.height - spr.height) / 2;

		return spr;
	}

	public static inline function screenCenterXY(spr:FlxObject):FlxObject
	{
		spr.x = (FlxG.width - spr.width) / 2;
		spr.y = (FlxG.height - spr.height) / 2;

		return spr;
	}
}