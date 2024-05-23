package;

import flixel.math.FlxRect;
import flixel.graphics.frames.FlxFramesCollection;
import editors.ChartingState;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

class Note extends FlxColorSwap
{
	//public var extraData:Map<String,Dynamic> = [];
	public var strumTime:Float = 0;
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	//public var tail:Array<Note> = []; // for sustains
	//public var parent:Note;

	public var sustainLength:Float = 0;
	public var isHoldEnd:Bool = false;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Single = 0.5;
	public var lateHitMult:Single = 1;
	public var lowPriority:Bool = false;

	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	// Lua shit
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;
	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;

	public var frozen(default, set):Bool;

	var _noteType:String;

	var _frozenFrames:FlxFramesCollection;
	var _cacheFrames:FlxFramesCollection;

	function set_frozen(value:Bool)
	{
		if (value != frozen)
		{
			frozen = value;

			if (frozen)
			{
				_noteType = noteType;

				noteType = "Frozen Note";
			}
			else
			{
				noteType = _noteType;

				reloadNote();
				_noteType = null;
			}
		}
		return value;
	}

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		//trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(isSustainNote && !isHoldEnd)
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String {
		if(texture != value) {
			reloadNote('', value);
			texture = value;
		}
		return value;
	}

	private function set_noteType(value:String):String {
		noteSplashTexture = PlayState.SONG.splashSkin;
		if(colorSwap != null) {
			var hsv = ClientPrefs.arrowHSV[noteData % 4];
			colorSwap.hue = hsv[0] / 360;
			colorSwap.saturation = hsv[1] / 100;
			colorSwap.brightness = hsv[2] / 100;
		}

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					reloadNote('HURT');
					noteSplashTexture = 'HURTnoteSplashes';
					if(colorSwap != null) {
						colorSwap.hue = 0;
						colorSwap.saturation = 0;
						colorSwap.brightness = 0;
					}
					lowPriority = true;

					if(isSustainNote) {
						missHealth = 0.1;
					} else {
						missHealth = 0.3;
					}
					hitCausesMiss = true;
				case 'Frozen Note':
					reloadNote(null, 'NOTE_ICED');
					noteSplashTexture = "noteSplashesICE";

					if (_frozenFrames == null)
						_frozenFrames = frames;

				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}
			noteType = value;
		}
		if(colorSwap != null) {
			noteSplashHue = colorSwap.hue;
			noteSplashSat = colorSwap.saturation;
			noteSplashBrt = colorSwap.brightness;
		}
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?frozenAssets:Bool = false)
	{
		super();
		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;

		x += (ClientPrefs.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.noteOffset;
		this.noteData = noteData;
		if(noteData > -1) {
			texture = '';
			if(ClientPrefs.hasArrowHSV()) {
				shader = getColorSwap();
			}

			x += swagWidth * (noteData % 4);
			if(!isSustainNote) { //Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				switch (noteData % 4)
				{
					case 0:
						animToPlay = 'purple';
					case 1:
						animToPlay = 'blue';
					case 2:
						animToPlay = 'green';
					case 3:
						animToPlay = 'red';
				}
				animation.play(animToPlay + 'Scroll');
			}
		}

		// trace(prevNote);

		if(prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if(ClientPrefs.downScroll) flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			switch (noteData)
			{
				case 0:
					animation.play('purpleholdend');
				case 1:
					animation.play('blueholdend');
				case 2:
					animation.play('greenholdend');
				case 3:
					animation.play('redholdend');
			}

			isHoldEnd = true;

			updateHitbox();

			offsetX -= width / 2;

			if (prevNote.isSustainNote)
			{
				switch (prevNote.noteData)
				{
					case 0:
						prevNote.animation.play('purplehold');
					case 1:
						prevNote.animation.play('bluehold');
					case 2:
						prevNote.animation.play('greenhold');
					case 3:
						prevNote.animation.play('redhold');
				}
				prevNote.isHoldEnd = false;

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(PlayState.instance != null)
				{
					prevNote.scale.y *= PlayState.instance.songSpeed;
				}

				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}
		} else if(!isSustainNote) {
			earlyHitMult = 1;
		}
		x += offsetX;
	}

	function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = '') {
		if(prefix == null) prefix = '';
		if(texture == null) texture = '';
		if(suffix == null) suffix = '';

		var skin:String = texture;
		if(texture.length < 1) {
			skin = PlayState.SONG.arrowSkin;
			if(skin == null || skin.length < 1) {
				skin = 'NOTE_assets';
			}
		}

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length-1] = prefix + arraySkin[arraySkin.length-1] + suffix;


		var lastScaleY:Float = scale.y;
		var blahblah:String = arraySkin.join('/');

		if (frozen && _cacheFrames == null)
			_cacheFrames = frames;
		frames = (frozen && _frozenFrames != null) ? _frozenFrames : (_cacheFrames != null) ? _cacheFrames : Paths.getSparrowAtlas(blahblah);

		loadNoteAnims();
		antialiasing = ClientPrefs.globalAntialiasing;

		if(isSustainNote) {
			scale.y = lastScaleY;
		}
		updateHitbox();

		if(animName != null)
			animation.play(animName, true);

		if(inEditor) {
			setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
			updateHitbox();
		}
	}

	static var notes = ["purple", "blue", "green", "red"];
	function loadNoteAnims() {
		//for (note in notes)
		//{
		var note = notes[noteData % 4];
		animation.addByPrefix('${note}Scroll', '${note}0');

		animation.addByPrefix('${note}holdend', (note == "purple") ? "pruple end hold" : '$note hold end');
		animation.addByPrefix('${note}hold', '$note hold piece');
		//}

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		switch(noteData) {
			case 0:
				animation.add('purpleholdend', [PURP_NOTE + 4]);
				animation.add('purplehold', [PURP_NOTE]);
				animation.add('purpleScroll', [PURP_NOTE + 4]);
			case 1:
				animation.add('blueholdend', [BLUE_NOTE + 4]);
				animation.add('bluehold', [BLUE_NOTE]);
				animation.add('blueScroll', [BLUE_NOTE + 4]);
			case 2:
				animation.add('greenholdend', [GREEN_NOTE + 4]);
				animation.add('greenhold', [GREEN_NOTE]);
				animation.add('greenScroll', [GREEN_NOTE + 4]);
			case 3:
				animation.add('redholdend', [RED_NOTE + 4]);
				animation.add('redhold', [RED_NOTE]);
				animation.add('redScroll', [RED_NOTE + 4]);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			// ok river
			if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult)
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				canBeHit = true;
			else
				canBeHit = false;

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
			{
				if((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}
}
