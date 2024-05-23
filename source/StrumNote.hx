package;

import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxMath;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class StrumNote extends FlxColorSwap
{
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;
	public var alloyEvent(default, set):Bool = false;
	public var frozen(default, set):Bool;

	var _frozenFrames:FlxFramesCollection;
	var _cacheFrames:FlxFramesCollection;

	private var player:Int;

	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}
	static var directions = ["left", "down", "up", "right"];
	public function new(x:Float, y:Float, leData:Int, player:Int) {
		this.player = player;
		this.noteData = leData;
		super(x, y);

		if(ClientPrefs.hasArrowHSV()) {
			shader = getColorSwap();
		}

		var skin:String = 'NOTE_assets';
		if(PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		texture = skin; //Load texture and anims

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;
		noteData = FlxMath.absInt(noteData);
		if (frozen)
		{
			if (_cacheFrames == null)
				_cacheFrames = frames;

			frames = _frozenFrames;
		}
		else
			frames = (alloyEvent) ? _cacheFrames : Paths.getSparrowAtlas(texture);

		antialiasing = ClientPrefs.globalAntialiasing;
		setGraphicSize(Std.int(width * 0.7));

		animation.addByPrefix('static', 'arrow${directions[noteData].toUpperCase()}');
		animation.addByPrefix('pressed', '${directions[noteData].toLowerCase()} press', 24, false);
		animation.addByPrefix('confirm', '${directions[noteData].toLowerCase()} confirm', 24, false);

		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function postAddedToGroup() {
		playAnim('static');
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
	}
	function set_alloyEvent(event:Bool)
	{
		if (event)
		{
			if (alloyEvent) return event;
			_frozenFrames = Paths.getSparrowAtlas("NOTE_ICED");
		}
		return alloyEvent = event;
	}
	function set_frozen(froze:Bool)
	{
		if (!alloyEvent) return false;

		if (froze != frozen)
		{
			frozen = froze;
			if (frozen)
			{
				texture = "NOTE_ICED";
				reloadNote();
			}
			else
			{
				texture = "NOTE_assets";
				if(PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) texture = PlayState.SONG.arrowSkin;
				reloadNote();
			}
		}
		return froze;
	}
	override function update(elapsed:Float) {
		super.update(elapsed);
		if (resetAnim <= 0) return;

		resetAnim -= elapsed;
		if(resetAnim <= 0) {
			playAnim('static');
			resetAnim = 0;
		}
	}

	public function playAnim(anim:String, ?force:Bool = false) {

		(animation.exists(anim)) ? animation.play(anim, force) : animation.play('confirm', force, false, 1);

		centerOffsets();
		centerOrigin();

		if(colorSwap == null) return;

		if(animation.curAnim == null || animation.curAnim.name == 'static') {
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		} else {
			var hsv = ClientPrefs.arrowHSV[noteData % 4];
			colorSwap.hue = hsv[0] / 360;
			colorSwap.saturation = hsv[1] / 100;
			colorSwap.brightness = hsv[2] / 100;
		}
	}
}
