package;

import openfl.Assets;
import Character.CharacterFile;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;

using StringTools;

class Boyfriend extends Character
{
	public var startedDeath:Bool = false;
	public var alloyShootEvent:Bool = false;
	public var dodged(default, set):Bool;
	public var frozen(get, null):Bool;
	public var frozenNoteCount(default, set):Int;
	var _gotframes:Bool = false;
	var _sufix:String = "";

	var _space:Bool = false;
	public function new(x:Float = 0, y:Float = 0, ?char:String = 'bf')
	{
		super(x, y, char, true);
	}
	override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0) 
	{
		if (frozen)
			AnimName = AnimName.replace("miss", "").split("-")[0];
		super.playAnim(AnimName, Force, Reversed, Frame);
	}
	override function update(elapsed:Float)
	{
		if (!debugMode && curAnimName != null)
		{
			if (curAnimName.startsWith('sing'))
			{
				holdTimer += elapsed;
			}
			else
				holdTimer = 0;

			if (curAnimName.endsWith('miss') && isFinishedAnim() && !debugMode)
			{
				playAnim('idle', true, false, 10);
			}

			if (curAnimName == 'firstDeath' && isFinishedAnim() && startedDeath)
			{
				playAnim('deathLoop');
			}

			if (curAnimName == 'attack' && isFinishedAnim())
			{
				playAnim("pre-attack");
				specialAnim = true;
			}

			if (!startedDeath && alloyShootEvent)
			{
				if (!dodged && (FlxG.keys.justPressed.SPACE && !PlayState.instance.cpuControlled))
				{
					dodged = true;
					_space = true;
				}
				
				if (dodged && (FlxG.keys.released.SPACE && _space || isFinishedAnim()))
				{
					dodged = false;
					_space = false;
					dance();
				}
			}
		}
		super.update(elapsed);
	}
	override function dance()
	{
		if (!frozen)
			super.dance();
	}
	function get_frozen()
	{
		return curCharacter.endsWith("-ice");
	}
	function set_dodged(dodge:Bool)
	{
		if (frozen)
			return false;

		dodge ? playAnim("dodge", true): dance();
		specialAnim = dodge;
		return dodged = dodge;
	}
	function set_frozenNoteCount(value:Int)
	{
		frozenNoteCount = (frozen) ? value : 0;

		if (frozenNoteCount == 20)
			frozen = false;

		return value;
	}
}