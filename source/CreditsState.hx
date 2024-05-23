package;

import flixel.FlxObject;
import flxanimate.animate.FlxElement;
import flxanimate.FlxAnimate;
import flxanimate.effects.FlxTint;
#if desktop
import Discord.DiscordClient;
#end
import openfl.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import lime.utils.Assets;

using StringTools;

class CreditsState extends MusicBeatState
{
	var curElement:FlxElement = null;

	var tint:FlxTint = new FlxTint(0, 0.5);

	var charStuff:Map<String, Array<Int>> = [
		"finny" => [200, -30], 
		"MC" => [0,0],
		"coco" => [100, 185],
		"cheems" => [-190, 0],
		"xeno" => [-230, 185],
		"mixbro" => [-150, -650],
		"spadezer" => [200, -700]
	];

	var zoomChar:Map<String, Float> = [
		"cheems" => 0.95,
		"MC" => 0.8,
		"mixbro" => 0.9
	];
	
	var credsSprite:FlxAnimate;

	var pepol:Array<FlxElement> = [];

	var names:FlxElement = null;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		credsSprite = new FlxAnimate(Paths.getTextureAtlas("credit stuff"), {Antialiasing: true});
		add(credsSprite);
		pepol = credsSprite.anim.curSymbol.timeline.get("pepol").get(0).getList().copy();
		for (person in pepol)
		{
			person.symbol.colorEffect = tint;

			if (person.symbol.name == "alloy")
			{
				person.symbol.colorEffect = null;
				pepol.remove(person);
			}
			if (person.symbol.name == "finny")
				person.symbol.colorEffect = tint;
		}
		names = credsSprite.anim.curSymbol.getElementByName("Names");
		camera.zoom = 0.6;
		super.create();
		camera.zoom = 1;
		changeSelection("");
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if(!quitting)
		{
			var leftP = controls.UI_LEFT_P;
			var rightP = controls.UI_RIGHT_P;
			var upP = controls.UI_UP_P;
			var downP = controls.UI_DOWN_P;
			if (leftP)
			{
				changeSelection("Left");
			}
			if (rightP)
			{
				changeSelection("Right");
			}
			if (upP)
			{
				changeSelection("Up");
			}
			if (downP)
			{
				changeSelection("Down");
			}

			if(controls.ACCEPT) 
			{
				CoolUtil.browserLoad(processUrl(curElement.symbol.instance));
			}
			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				quitting = true;
			}
		}
		super.update(elapsed);
	}

	function processUrl(string:String) 
	{
		var linkNG:Bool = true;
		if (string.contains("dotcom"))
			linkNG = false;

		string = string.replace("dot", ".");
		string = string.replace("slash", "/");
		string = string.replace("minus", "-");
		
		return "https://" + ((linkNG) ? string + ".newgrounds.com" : string);
	}


	function changeSelection(pos:String)
	{		
		if (curElement == null)
		{
			curElement = credsSprite.anim.curSymbol.getElementByName("MC", 0);
			var finny = credsSprite.anim.curSymbol.getElementByName("finny", 0);
			finny.symbol.colorEffect = tint;
			finny.symbol.firstFrame = 1;
		}
		else
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			curElement.symbol.colorEffect = tint;
			curElement.symbol.firstFrame = 1;
			
			var pos = credsSprite.anim.symbolDictionary[curElement.symbol.name].timeline.get(pos).get(0).name;
			curElement = credsSprite.anim.curSymbol.getElementByName(pos);
		}
		
		curElement.symbol.colorEffect = null;
		curElement.symbol.firstFrame = 0;
		
		var symbolName = curElement.symbol.name;
		var charX = charStuff[symbolName][0];
		var charY = charStuff[symbolName][1];
		FlxTween.cancelTweensOf(credsSprite);
		FlxTween.tween(credsSprite, {x: charX, y: charY}, 1, {ease: FlxEase.quartOut});
		var zoom = (zoomChar.exists(symbolName)) ? zoomChar[symbolName] : 1;
		FlxTween.cancelTweensOf(camera);
		FlxTween.tween(camera, {zoom: zoom}, 1, {ease: FlxEase.quartOut});


		names.symbol.firstFrame = credsSprite.anim.symbolDictionary.get(names.symbol.name).getFrameLabel(curElement.symbol.name).index;


	}
}