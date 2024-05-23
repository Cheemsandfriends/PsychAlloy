package;

import flixel.animation.FlxAnimationController;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import editors.ChartingState;

using StringTools;


class ChartNote extends Note
{
	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';
}
