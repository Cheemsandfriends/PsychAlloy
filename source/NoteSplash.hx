package;

import flixel.FlxG;

class NoteSplash extends FlxColorSwap
{
	private var idleAnim:String;
	private var textureLoaded:String = null;

	public static var texturesLoaded:Map<String, NoteSplash> = [];

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0) {
		super(x, y);
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		loadAnims(skin);

		if(ClientPrefs.hasArrowHSV()) {
			shader = getColorSwap();
		}

		animation.finishCallback = (_) -> kill();

		setupNoteSplash(x, y, note);
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = null, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0) {
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		var offx = -20;
		var offy = 215;
		switch (note)
		{
			case 0:
				offx = 120;
				offy = 220;
		}
		if (texture != null && StringTools.endsWith(texture, "ICE"))
		{
			alpha = 0.6;
			offx = 10;
			offy = -100;
		}
		offset.set(offx, offy);
		if(texture == null) {
			texture = 'noteSplashes';
			if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) texture = PlayState.SONG.splashSkin;
		}
		if(textureLoaded != texture) {
			loadAnims(texture);
		}
		//revive();
		if(colorSwap != null) {
			colorSwap.hue = hueColor;
			colorSwap.saturation = satColor;
			colorSwap.brightness = brtColor;
		}

		animation.play('note' + note, true);
		if(animation.curAnim != null)
			animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
	}

	function loadAnims(skin:String) {
		if (texturesLoaded.exists(skin))
			frames = texturesLoaded[skin].frames;
		else
		{
			frames = Paths.getSparrowAtlas(skin);
			texturesLoaded.set(skin, this);
		}

		var notes = ["purple", "blue", "green", "red"];
		for (i in 0...4) {
			var note = (StringTools.endsWith(skin, "ICE")) ? '${notes[i]}_ice_splash' : 'note_splash_${notes[i]}';
			animation.addByPrefix('note'+ i, note, 24, false);
		}

		textureLoaded = skin;
	}
}