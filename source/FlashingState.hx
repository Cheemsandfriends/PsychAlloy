package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var warnText:FlxText;

	// if you want to modify this function, it should be ez, but I recommend using a `function()` instead of `() ->` if you wanna do more lines than this lmao.
	var func = (tmr:Dynamic) -> MusicBeatState.switchState(new TitleState());
	var duration = 1;
	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width,
			"Hey, watch out!\n
			This Mod contains some flashing lights!\n
			Press ENTER to disable them now or go to Options Menu.\n
			Press ESCAPE to ignore this message.\n
			You've been warned!",
			32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);
	}

	override function update(elapsed:Float)
	{
		if(!leftState) {
			var back:Bool = controls.BACK;
			if (controls.ACCEPT || back) {
				leftState = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				ClientPrefs.flashing = back;
				ClientPrefs.saveSettings();

				FlxG.sound.play(Paths.sound('${(controls.ACCEPT) ? "confirm" : "cancel"}Menu'));
				
				if(!back) {
					FlxFlicker.flicker(warnText, duration, 0.1, false, true, function(flk:FlxFlicker) {
						new FlxTimer().start(0.5, func);
					});
				} else {
					FlxTween.tween(warnText, {alpha: 0}, duration, {onComplete: func});
				}
			}
		}
		super.update(elapsed);
	}
}
