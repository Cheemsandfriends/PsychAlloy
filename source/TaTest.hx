package;

import flixel.ui.FlxBar;
import flixel.addons.ui.FlxSlider;
import flxanimate.frames.FlxAnimateFrames;
import flixel.sound.FlxSound;
import flxanimate.FlxAnimate;
import flixel.FlxG;
import flixel.FlxSprite;

class TaTest extends MusicBeatState 
{
    var togglePlay:FlxSprite = null;

    var playableTAs:Array<FlxAnimate> = [];

    var testSong:FlxSound = null;

    var bar:FlxBar = null;
    override public function create()
    {
        // Im TOO lazy to even care, so uh, yep
        FlxG.camera.zoom = 0.66666666666666666666666666666667;
        FlxG.camera.scroll.x = FlxG.width - (FlxG.width * FlxG.camera.zoom);
        FlxG.camera.scroll.y = (FlxG.height - (FlxG.height * FlxG.camera.zoom)) * 0.75;

        FlxG.mouse.visible = true;


        super.create();

        Paths.setCurrentLevel("weekalloy");


        instanceTA("STAGE");
        playableTAs = [
            instanceTA("LIGHTS"),
            instanceTA("BF"),
            instanceTA("ALLOY")
        ];

        testSong = new FlxSound();
        testSong.loadEmbedded(Paths.music("AlloyTest"));
        FlxG.sound.list.add(testSong);

        bar = new FlxBar(-300, -100, LEFT_TO_RIGHT, Math.ceil(FlxG.width / FlxG.camera.zoom) - 25, 30, testSong, "time", 0, testSong.length);
        bar.numDivisions = 4000000;
        
        bar.scrollFactor.set();
        
        add(bar);

        togglePlay = new FlxSprite();
        togglePlay.frames = FlxAnimateFrames.fromCocos2D(Paths.getPath("images/TEST/toggle.plist", TEXT));
        togglePlay.scrollFactor.set();
        togglePlay.scale.scale(FlxG.camera.zoom + 1);
        togglePlay.updateHitbox();
        togglePlay.antialiasing = ClientPrefs.globalAntialiasing;
        add(togglePlay);
        togglePlay.animation.frameIndex = 1;
        
        playableTAs[0].anim.onComplete = () -> togglePlay.animation.frameIndex = 1;
    }

    function instanceTA(path:String)
    {
        var TA = new FlxAnimate(Paths.getTextureAtlas("TEST/" + path));
        TA.anim.stageInstance.symbol.loop = PlayOnce;
        TA.antialiasing = ClientPrefs.globalAntialiasing;

        add(TA);

        return TA;
    }
    var diffT:Bool = false;

    var selectedBar:Bool = false;
    override function update(elapsed:Float) 
    {
        
        super.update(elapsed);
        @:privateAccess
        var fr = Math.floor(testSong.time * 0.001 / playableTAs[0].anim.frameDelay);
        playableTAs[0].anim.curFrame = fr;
        playableTAs[1].anim.curFrame = fr;
        playableTAs[2].anim.curFrame = fr;

        if (controls.ACCEPT)
            toggle();

        if (controls.BACK)
        {
            FlxG.sound.music.play();
            FlxG.mouse.visible = false;

            MusicBeatState.switchState(new MainMenuState());
        }
        if (FlxG.mouse.overlaps(bar) && FlxG.mouse.pressed)
            selectedBar = true;
        
        if (FlxG.mouse.released)
            selectedBar = false;

        if (selectedBar)
        {
            var percent = (FlxG.mouse.screenX + bar.x)  / bar.width * 100 + 31;
            bar.percent = percent;

            testSong.time = testSong.length * percent * 0.01;
        }
    }

    function toggle()
    {
        if (testSong.playing)
        {
            togglePlay.animation.frameIndex = 1;
            testSong.pause();
        }
        else
        {
            togglePlay.animation.frameIndex = 0;
            testSong.play();
        }
    }
}