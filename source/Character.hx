package;

import flixel.math.FlxPoint;
import flxanimate.FlxAnimate;
import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import Song;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;

using StringTools;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	var funcs:Map<String, ()->Void> = [];

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	public var hasMissAnimations:Bool = false;

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];
	
	public var curAnimName:Null<String> = null;
	
	var atlas:FlxAnimate = null;

	var ogRes:FlxPoint;
	

	public static var DEFAULT_CHARACTER:String = 'bf'; //In case a character is missing, it will use BF on its place
	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end
		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = ClientPrefs.globalAntialiasing;
		
		switch (curCharacter)
		{
			//case 'your character name in case you want to hardcode them instead':

			default:
				var characterPath:String = 'characters/' + curCharacter + '.json';

				#if MODS_ALLOWED
				var path:String = Paths.modFolders(characterPath);
				if (!FileSystem.exists(path)) {
					path = Paths.getPreloadPath(characterPath);
				}

				if (!FileSystem.exists(path))
				#else
				var path:String = Paths.getPreloadPath(characterPath);
				if (!Assets.exists(path))
				#end
				{
					path = Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
				}

				#if MODS_ALLOWED
				var rawJson = File.getContent(path);
				#else
				var rawJson = Assets.getText(path);
				#end

				var json:CharacterFile = cast Json.parse(rawJson);
				var spriteType = "sparrow";
				//sparrow
				//packer
				//texture
				#if MODS_ALLOWED
				var modTxtToFind:String = Paths.modsTxt(json.image);
				var txtToFind:String = Paths.getPath('images/' + json.image + '.txt', TEXT);
				
				//var modTextureToFind:String = Paths.modFolders("images/"+json.image);
				//var textureToFind:String = Paths.getPath('images/' + json.image, new AssetType();
				
				if (FileSystem.exists(modTxtToFind) || FileSystem.exists(txtToFind) || Assets.exists(txtToFind))
				#else
				if (Assets.exists(Paths.getPath('images/' + json.image + '.txt', TEXT)))
				#end
				{
					spriteType = "packer";
				}
				
				#if MODS_ALLOWED
				var modAnimToFind:String = Paths.modFolders('images/' + json.image + '/Animation.json');
				var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT);
				
				//var modTextureToFind:String = Paths.modFolders("images/"+json.image);
				//var textureToFind:String = Paths.getPath('images/' + json.image, new AssetType();
				
				if (FileSystem.exists(modAnimToFind) || FileSystem.exists(animToFind) || Assets.exists(animToFind))
				#else
				if (Assets.exists(Paths.getPath('images/' + json.image + '/Animation.json', TEXT)))
				#end
				{
					spriteType = "texture";
				}

				switch (spriteType){
					
					case "packer":
						frames = Paths.getPackerAtlas(json.image);
					
					case "sparrow":
						frames = Paths.getSparrowAtlas(json.image);
					
					case "texture":
						makeGraphic(1, 1, 0);
						atlas = new FlxAnimate();
						atlas.loadAtlas(Paths.getTextureAtlas(json.image));

						atlas.alpha = 0.0001;
						atlas.draw();

						atlas.alpha = alpha;

						if (mainPivot != null)
							mainPivot = atlas.anim.symbolDictionary[atlas.anim.stageInstance.symbol.name].getElement(0, 0).symbol.transformationPoint;
						else
							mainPivot = FlxPoint.get();

						ogRes = FlxPoint.get(atlas.width, atlas.height);
				}
				imageFile = json.image;

				if(json.scale != 1) {
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				positionArray = json.position;
				cameraPosition = json.camera_position;

				healthIcon = json.healthicon;
				singDuration = json.sing_duration;
				flipX = !!json.flip_x;
				if(json.no_antialiasing) {
					antialiasing = false;
					noAntialiasing = true;
				}

				if(json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				antialiasing = !noAntialiasing;
				if(!ClientPrefs.globalAntialiasing) antialiasing = false;

				
				if (spriteType == "texture")
				{
					var anims = atlas.anim.curSymbol.getFrameLabelNames();
					for (anim in anims)
						addOffset(anim, 0, 0);
				}
				else
				{
					animationsArray = json.animations;
					if(animationsArray != null && animationsArray.length > 0) {
						for (anim in animationsArray) {
								var animAnim:String = '' + anim.anim;
								var animName:String = '' + anim.name;
								var animFps:Int = anim.fps;
								var animLoop:Bool = !!anim.loop; //Bruh
								var animIndices:Array<Int> = anim.indices;
								if(animIndices != null && animIndices.length > 0) {
									animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
								} else {
									animation.addByPrefix(animAnim, animName, animFps, animLoop);
								}
	
							if(anim.offsets != null && anim.offsets.length > 1) {
								addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
							}
						}
					} else {
						quickAnimAdd('idle', 'BF idle dance');
					}
				}
				//trace('Loaded file to character ' + curCharacter);
		}
		switch (curCharacter)
		{
			case "alloy":
				atlas.anim.metadata.showHiddenLayers = false;
				var hide = atlas.anim.symbolDictionary["Alloy/A_calf"];
				hide.hideLayer("calf");
				hide = atlas.anim.symbolDictionary["Alloy/a_footA"];
				hide.hideLayer("calf");

				var symb = ["A_FACE", "a_head1"];

				for (symbol in symb)
				{
					hide = atlas.anim.symbolDictionary["Alloy/" + symbol];
					hide.hideLayer("Contour");
					hide.hideLayer("Mask");
				}
			case "alloyarmor":
				atlas.anim.metadata.showHiddenLayers = false;
				var hide = atlas.anim.symbolDictionary["Alloy/A_FACE"];
				hide.hideLayer("Face");
				var anims = ["singRIGHT", "singLEFT", "singUP", "singDOWN", "singRIGHThold", "singLEFThold", "singUPhold", "singDOWNhold"];
				for (anim in anims)
				{
					var frame = atlas.anim.symbolDictionary[atlas.anim.stageInstance.symbol.name].getFrameLabel(anim);
					var frame2 = atlas.anim.symbolDictionary[atlas.anim.stageInstance.symbol.name].getFrameLabel(anim + "-alt");
					if (frame2 != null)
					{
						frame2.name = anim;

						var thing = animOffsets[frame2.name];
						animOffsets.remove(frame2.name + "-alt");
						animOffsets.set(anim, thing);
					}
					
					if (frame != null)
					{
						frame.name = anim + "-alt";

						var thing = animOffsets[anim];
						animOffsets.remove(anim);
						animOffsets.set(frame.name, thing);
					} 
				}
				

		}
		originalFlipX = flipX;

		if (isPlayer)
			flipX = !flipX;
		copyAtlasValues();

		if(animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss')) hasMissAnimations = true;
		recalculateDanceIdle();
		dance();

		if (isPlayer)
		{
			// flipX = !flipX;

			/*// Doesn't flip for BF, since his are already in the right place???
			if (!curCharacter.startsWith('bf'))
			{
				// var animArray
				if(animation.getByName('singLEFT') != null && animation.getByName('singRIGHT') != null)
				{
					var oldRight = animation.getByName('singRIGHT').frames;
					animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
					animation.getByName('singLEFT').frames = oldRight;
				}

				// IF THEY HAVE MISS ANIMATIONS??
				if (animation.getByName('singLEFTmiss') != null && animation.getByName('singRIGHTmiss') != null)
				{
					var oldMiss = animation.getByName('singRIGHTmiss').frames;
					animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
					animation.getByName('singLEFTmiss').frames = oldMiss;
				}
			}*/
		}
	}

	public function getCurAnimName():Null<String>
	{
		if (atlas != null)
			return atlas.anim.curInstance.symbol.instance;

		return (animation.curAnim != null) ? animation.curAnim.name : null;
	}

	public function getCurAnimFrame():Int
	{
		if (atlas != null)
		{
			return atlas.anim.curFrame;
		}

		return animation.curAnim.curFrame;
	}

	public function onCompleteFunction(func:(name:String)->Void)
	{
		if (atlas != null)
		{
			if (func != null)
				atlas.anim.onComplete = func.bind(curAnimName);
			else
				atlas.anim.onComplete = null;
			return;
		}

		animation.finishCallback = func;
	}

	public function isFinishedAnim()
	{
		if (atlas != null)
			return atlas.anim.finished;

		return animation.finished;
	}

	public function finishAnim()
	{
		if (atlas != null)
		{
			atlas.anim.finish();
			return;
		}

		animation.finish();
	}
	override function update(elapsed:Float)
	{
		if(!debugMode && curAnimName != null)
		{
			if(heyTimer > 0)
			{
				heyTimer -= elapsed;
				if(heyTimer <= 0)
				{
					if(specialAnim && curAnimName == 'hey' || curAnimName == 'cheer')
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			} else if(specialAnim && isFinishedAnim())
			{
				specialAnim = false;
				dance();
			}
			
			switch(curCharacter)
			{
				case 'pico-speaker':
					if(animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
					{
						var noteData:Int = 1;
						if(animationNotes[0][1] > 2) noteData = 3;

						noteData += FlxG.random.int(0, 1);
						playAnim('shoot' + noteData, true);
						animationNotes.shift();
					}
					if(isFinishedAnim()) playAnim(curAnimName, false, false, animation.curAnim.frames.length - 3);
			}

			if (!isPlayer)
			{
				if (curAnimName.startsWith('sing'))
				{
					holdTimer += elapsed;
				}

				if (holdTimer >= Conductor.stepCrochet * 0.0011 * singDuration)
				{
					dance();
					holdTimer = 0;
				}
			}

			if(isFinishedAnim() && animOffsets.get(curAnimName + '-loop') != null)
			{
				playAnim(curAnimName + '-loop');
			}
		}
		super.update(elapsed);

		if (atlas != null)
			atlas.update(elapsed);
	}
	override public function draw() 
	{
		super.draw();

		if (atlas != null)
		{
			copyAtlasValues();
			atlas.draw();
		}
	}

	public function copyAtlasValues()
	{
		@:privateAccess
		if (atlas != null)
		{
			width = atlas.width;
			height = atlas.height;
			frameWidth = Math.ceil(atlas.width);
			frameHeight = Math.ceil(atlas.width);
			atlas.cameras = cameras;
			atlas.scrollFactor = scrollFactor;
			atlas.scale = scale;
			atlas.origin = origin;
			atlas.x = x;
			atlas.y = y;
			atlas.colorTransform = colorTransform;
			atlas.angle = angle;
			atlas.alpha = alpha;
			atlas.visible = visible;
			atlas.antialiasing = antialiasing;
		}
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			if(danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if(animOffsets.get('idle' + idleSuffix) != null) {
					playAnim('idle' + idleSuffix);
			}
		}
	}

	var mainPivot:FlxPoint;
	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		if (atlas != null)
		{
			if (AnimName.contains("-alt") && !animOffsets.exists(AnimName))
			{
				AnimName = AnimName.replace("-alt", "");
			}
			if (flipX && AnimName.startsWith("sing"))
			{
				if (AnimName.contains("LEFT"))
					AnimName = AnimName.replace("LEFT", "RIGHT");
				else if (AnimName.contains("RIGHT"))
					AnimName = AnimName.replace("RIGHT", "LEFT");
			}
			var label = atlas.anim.symbolDictionary[atlas.anim.stageInstance.symbol.name].getFrameLabel(AnimName);
			if (label != null)
			{
				var element = label.get(0);
			
				if (element != null)
				{
					if (mainPivot == null)
						mainPivot = atlas.anim.symbolDictionary[atlas.anim.stageInstance.symbol.name].getFrameLabel("idle").get(0).symbol.transformationPoint;
					if (flipX && element.matrix.a > 0.)
					{
						element.matrix.a -= element.matrix.a * 2;
						element.matrix.tx += (mainPivot.x - element.matrix.tx) * 2;
						atlas.offset.x = -ogRes.x;
					}
					else if (!flipX && element.matrix.a < 0.)
					{
						element.matrix.a += -element.matrix.a * 2;
						element.matrix.tx -= (mainPivot.x - element.matrix.tx) * 2;
						element.matrix.tx -= ogRes.x;
						atlas.offset.x = 0;

					}
				}

				atlas.anim.playElement(element, Force, Reversed, Frame);
			}
		}
		else
		{
			animation.play(AnimName, Force, Reversed, Frame);

			var daOffset = animOffsets.get(AnimName);
			if (animOffsets.exists(AnimName))
			{
				offset.set(daOffset[0] * scale.x, daOffset[1] * scale.y);
			}
			else
				offset.set(0, 0);
		}

		curAnimName = AnimName;
		

		if (curCharacter.startsWith('gf'))
		{
			if (AnimName == 'singLEFT')
			{
				danced = true;
			}
			else if (AnimName == 'singRIGHT')
			{
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animOffsets.get('danceLeft' + idleSuffix) != null && animOffsets.get('danceRight' + idleSuffix) != null);

		if(settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		if (atlas == null)
			animation.addByPrefix(name, anim, 24, false);
	}
}
