package;

import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxState;
import flixel.FlxBasic;

class MusicBeatState extends FlxUIState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	var addGrp:Map<FlxBasic, Array<FlxBasic>> = [];

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function create() {
		var skip:Bool = FlxTransitionableState.skipNextTransIn;
		super.create();
		if(!skip) {
			openSubState(new CustomFadeTransition(0.7, true));
		}
		FlxTransitionableState.skipNextTransIn = false;
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		if (stepsToDo == 0) return;
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}
	override public function add(Object:FlxBasic):FlxBasic 
	{
		var thing = super.add(Object);
		var grp = addGrp.get(Object);
		if (grp != null)
		{
			for (member in grp)
			{
				add(member);
			}
		}

		addGrp.remove(Object);
		return thing;
	}
	public function addInFront(Object:FlxBasic, Object2:FlxBasic)
	{
		var array = addGrp.get(Object2);
		if (array == null) array = [];
		array.push(Object);
		addGrp.set(Object2, array);
	}
	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState) {
		// Custom made Trans in
		var curState:FlxState = FlxG.state;
		var leState:MusicBeatState = cast curState;
		if(!FlxTransitionableState.skipNextTransOut) {
			leState.openSubState(new CustomFadeTransition(0.6, false));
			CustomFadeTransition.finishCallback = function() {
				(nextState == curState) ? FlxG.resetState() : FlxG.switchState(#if (flixel>="6.0.0")()->nextState #else nextState#end);
			};
			return;
		}
		FlxTransitionableState.skipNextTransOut = false;
		FlxG.switchState(#if (flixel>="6.0.0")()->nextState #else nextState#end);
	}

	public static function resetState() {
		FlxG.resetState();
	}

	public static function getState():MusicBeatState {
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		//return [0.0,null].indexOf(val) != -1 ? 4 : val;
		if(val == null) return 4.0;
		if(val == 0.0) return 4.0;
		return val;
	}
}
