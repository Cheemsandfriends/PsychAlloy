package;

import flxanimate.FlxAnimate;
import flixel.math.FlxPoint;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Application;
#if ACHIEVEMENTS_ALLOWED
import Achievements;
#end
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;
import options.OptionsState;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.6.1'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		'options'
	];

	var debugKeys:Array<FlxKey>;
	var arm:AtlasArm;
	var trans:FlxAnimate;
	public var hand:HandSprite;

	var bf:Boyfriend;
	var bf2:FlxAnimate = null;

	public static var switchLevel:Bool = false;

	override function create()
	{
		Paths.clearStoredMemory();
		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		Paths.currentLevel = "weekalloy";

		var scale = 0.5;
		var time = "day";

		var stagePos = new FlxPoint(-100, -100);
		var sky = new BGSprite('$time/sky',  -500 + stagePos.x, -190 + stagePos.y, 0.3, 0.3);
		sky.scaleGraphic(scale + 1);
		add(sky);
		var sumoBldg = new BGSprite('$time/sumoSkyScraper', -430 + stagePos.x, 100 + stagePos.y, 0.4, 0.4);
		sumoBldg.scaleGraphic(scale);
		add(sumoBldg);
		var bldgs = new BGSprite('$time/buildings', -350 + stagePos.x, 30 + stagePos.y, 0.5, 0.5);
		bldgs.scaleGraphic(scale - 0.1);
		add(bldgs);
		var planes = new BGSprite('$time/planes', -300 + stagePos.x, 200 + stagePos.y, 0.8, 0.8);
		planes.scaleGraphic(scale);
		add(planes);
		var floor = new BGSprite('$time/floor', -300 + stagePos.x, 700 + stagePos.y, 0.9, 0.9);
		floor.scaleGraphic(scale);
		add(floor);

		bf = new Boyfriend("tzenbf");
		bf.idleSuffix = "-alt";

		bf.setGraphicSize(Std.int(bf.width * 0.5));
		bf.updateHitbox();
		bf.setPosition(FlxG.width - bf.frameWidth + 100, FlxG.height - bf.frameHeight + 60);
		bf.dance();

		add(bf);

		Paths.currentLevel = null;

		var vignette = new FlxSprite(Paths.image("mainmenu/menuVignette"));
		vignette.camera = camAchievement;
		add(vignette);

		var menu = -1;
		if (switchLevel)
			menu = (PlayState.isStoryMode) ? 0 : 1;
		arm = new AtlasArm(curSelected, menu);
		add(arm);
		trans = new FlxAnimate(Paths.getTextureAtlas("mainmenu/transitions"));
		trans.antialiasing = ClientPrefs.globalAntialiasing;
		trans.visible = false;
		add(trans);

		hand = new HandSprite();
		add(hand);

		MainMenuState.switchLevel = false;

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, 'Psych Engine v$psychEngineVersion', 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		hand.state = LIFTING;
		super.create();
		Paths.clearUnusedMemory();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}
		if (FlxG.keys.justPressed.Q)
		{
			FlxG.camera.zoom -= 0.25;
		}
		if (FlxG.keys.justPressed.E)
		{
			FlxG.camera.zoom += 0.25;
		}

		super.update(elapsed);

		if (arm.state != LIFTING && !selectedSomethin)
		{
			if (controls.UI_UP_P || controls.UI_DOWN_P)
			{
				var point = (controls.UI_UP_P) ? new FlxPoint(-200, 90) : new FlxPoint(-130, 50);

				scrollHand(point, function()
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeItem((point.x == -200) ? -1 : 1);
					selectedSomethin = false;
				});
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				if (arm.menu == "main")
				{
					bf.playAnim("singLEFTmiss", true);
					bf.skipDance = true;
					MusicBeatState.switchState(new TitleState());
				}
				else
				{
					arm.changeMenu("main");
					curSelected = (PlayState.isStoryMode) ? 0 : 1;
					selectedSomethin = false;
					changeItem();
				}
			}
			if ((controls.UI_LEFT_P || controls.UI_RIGHT_P) && selectinLevels())
			{
				var point = (controls.UI_LEFT_P) ? new FlxPoint(100, -50) : new FlxPoint(190, -80);
				scrollHand(point, function()
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					arm.difficulty += (point.x == 100) ? -1 : 1;
					selectedSomethin = false;
				});
			}
			if (FlxG.keys.justPressed.EIGHT)
			{
				FlxG.sound.music.stop();
				MusicBeatState.switchState(new TaTest());
			}

			if (controls.ACCEPT)
			{
				var curMenu = arm.options[curSelected].name;

				scrollHand(new FlxPoint(0, 0), function()
				{
					if (arm.state == UNLOCKED)
					{
						FlxG.sound.play(Paths.sound('confirmMenu'));
						var label = trans.anim.getFrameLabel(curMenu.charAt(0).toUpperCase() + curMenu.substring(1) + " STOP", "LABELS");
						if (label != null)
						{
							arm.transition();
							label.add(() -> trans.anim.pause());
							trans.anim.goToFrameLabel(curMenu.charAt(0).toUpperCase() + curMenu.substring(1));
							trans.visible = true;
							(curMenu == "awards") ? label.add(() -> MusicBeatState.switchState(new AchievementsMenuState())) : hand.anim.onComplete = () -> MusicBeatState.switchState(new CreditsState());
						}
						else
							arm.flicker(()-> changeMenu(curMenu));

						if (arm.menu != "main")
						{
							bf.playAnim("pre-attack", true);
							bf.skipDance = true;
						}

					}
					else
					{
						FlxG.sound.play(Paths.sound('cancelMenu'));
						selectedSomethin = false;
					}
				});
				if (curMenu == "credits")
					hand.state = CREDITS;
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}
	}
	function scrollHand(pos:FlxPoint, onPress:()->Void)
	{
		selectedSomethin = true;
		hand.state = IDLE;
		if(pos != null)
			hand.setPosition(pos.x, pos.y);
		else
			hand.setPosition();
		hand.onPress = onPress;
		hand.state = PRESSING;
	}
	function changeMenu(choice:String)
	{
		if (arm.menu == "main")
		{
			if (!selectinLevels(choice.split("_")[0]))
			{
				if (choice == "mods")
					MusicBeatState.switchState(new ModsMenuState());
				else
					MusicBeatState.switchState(new OptionsState());
				return;
			}
			PlayState.isStoryMode = choice == "story_mode";

			WeekData.reloadWeekFiles(PlayState.isStoryMode);

			arm.changeMenu((PlayState.isStoryMode) ? "story" : "freeplay");
			CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
			var options:Array<String> = [];

			if (PlayState.isStoryMode)
			{
				options = WeekData.weeksList;
			}
			else
			{
				for (week in WeekData.weeksLoaded.iterator())
				{
					for (song in week.songs)
						options.push(song.toLowerCase());
				}
			}

			if (!MainMenuState.switchLevel)
			{
				curSelected = 0;
				changeItem();
			}
			else
			{
				arm.difficulty = PlayState.storyDifficulty;
				changeItem();
			}


			selectedSomethin = false;

			return;
		}
		else
		{
			bf.playAnim("attack", true);
			bf.specialAnim = true;


			var songs:Array<String> = [];

			if (PlayState.isStoryMode)
			{
				var week = WeekData.weeksLoaded[choice];
				WeekData.setDirectoryFromWeek(WeekData.weeksLoaded[choice]);
				songs = week.songs;
			}
			else
			{
				songs = [arm.options[curSelected].name];
			}

			PlayState.storyPlaylist = songs;
			PlayState.storyDifficulty = arm.difficulty;

			var diff = CoolUtil.getDifficultyFilePath();

			if (diff == null)
				diff = "";

			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diff, PlayState.storyPlaylist[0].toLowerCase());

			StageData.loadDirectory(PlayState.SONG);

			PlayState.campaignScore = 0;
			PlayState.campaignMisses = 0;

			MainMenuState.switchLevel = true;
			LoadingState.loadAndSwitchState(new PlayState(), true);
		}
	}

	function selectinLevels(?ref:String = null)
	{
		if (ref == null)
			ref = arm.menu;

		return ["story", "freeplay", "bonus"].indexOf(ref) != -1;
	}
	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected > arm.options.length - 1)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = arm.options.length - 1;



		arm.changeOption(arm.options[curSelected].name);

		var song = arm.options[curSelected].name;
		if (arm.menu == "freeplay" || arm.menu == "bonus")
		{
			if (WeekData.weeksLoaded["weekExtras"].songs.indexOf(song.charAt(0).toUpperCase() + song.substring(1)) != -1)
				arm.changeMenu("bonus");
			else
				arm.changeMenu("freeplay");
		}
	}
	override function beatHit()
	{
		super.beatHit();
		if (curBeat % bf.danceEveryNumBeats == 0)
		{
			@:privateAccess
			bf.dance();
		}
	}
}
