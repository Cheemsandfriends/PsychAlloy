package;

import flixel.math.FlxMath;
import flxanimate.animate.FlxLayer;
import flixel.effects.FlxFlicker;
import flixel.FlxObject;
import flxanimate.animate.FlxKeyFrame;
import flxanimate.animate.FlxSymbol;
import flxanimate.FlxAnimate;

enum AtlasState
{
    LIFTING;
    UNLOCKED;
    LOCKED;
}
class AtlasArm extends FlxAnimate
{
    public var state(default, set):AtlasState;

    public var options:Array<FlxKeyFrame> = [];

    public var menu:String = "";

    public var difficulty(default, set):Int;

    var subMenu:FlxSymbol = null;
    var menuLayer:FlxLayer = null;
    var subMenuLayer:FlxLayer = null;

    var menuObject:FlxObject;

    var subMenuObject:FlxObject;


    var flickering:Bool = false;

    public function new(curSelected:Int = 0, ?menu:Int = -1)
    {
        super(Paths.getTextureAtlas("mainmenu/arm"));

        antialiasing = ClientPrefs.globalAntialiasing;
        state = LIFTING;

        anim.getFrameLabel("UNLOCKED").add(() ->
        {
            state = UNLOCKED;
            anim.removeAllCallbacksFrom("UNLOCKED");
            changeMenu((menu == -1) ? "main" : (menu == 0) ? "story" : "freeplay");
            changeOption(options[curSelected].name);
        });

        menuObject = new FlxObject();
        subMenuObject = new FlxObject();

        anim.curSymbol.timeline.get("diffcultyBlocks").visible = false;

    }

    public function changeMenu(value:String)
    {
        var menu = anim.getByInstance("Menu");

        var frame = menu.getFrameLabel(value);

        this.menu = value;
        anim.curSymbol.getElementByName("Menu").symbol.firstFrame = frame.index;

        if (subMenu == null)
            subMenu = anim.getByInstance("SubMenu");

        if (value != "bonus")
        {
            var menuLabel = subMenu.getFrameLabel(value.toUpperCase(), "MENUS");

            var isLevels = ["STORY", "FREEPLAY"].indexOf(menuLabel.name) != -1;

            anim.curSymbol.timeline.get("diffcultyBlocks").visible = isLevels;

            options = subMenu.getFrameLabels("NAMES");

            options = options.filter(function (f)
            {
                if (isLevels && f.name == "tutorial")
                    return true;

                return f.index >= menuLabel.index && f.index + f.duration <= menuLabel.index + menuLabel.duration;
            });
        }
    }
    public function changeOption(value:String)
    {
        if (options != null)
        {
            var subM = anim.curSymbol.getElementByName("SubMenu");
            var index = subMenu.getFrameLabel(value, "NAMES").index;

            var changed:Bool = false;
            if (subMenu.timeline.get("CHECK").get(index).name == "UNLOCKED")
            {
                changed = state != UNLOCKED;
                state = UNLOCKED;
            }
            else
            {
                changed = state != LOCKED;
                state = LOCKED;
            }
            if (changed)
            {
                subM = anim.curSymbol.getElementByName("SubMenu");
                changeMenu(menu);
                difficulty = difficulty;
            }
            subM.symbol.firstFrame = index;

        }
    }

    function set_difficulty(value:Int)
    {
        value %= CoolUtil.difficulties.length;
        if (value < 0)
            value = CoolUtil.difficulties.length - 1;

        anim.curSymbol.getElementByName("DifficultyBlocks").symbol.firstFrame = value;
        return difficulty = value;
    }

    function set_state(value:AtlasState)
    {
        if (state != value)
        {
            state = value;
            anim.goToFrameLabel(state.getName(), "STATES");

            if (state != LIFTING)
            {
                anim.pause();

            }
        }

        return value;
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (menuLayer != null)
        {
            menuLayer.visible = menuObject.visible;
            subMenuLayer.visible = subMenuObject.visible;
        }
    }
    public function flicker(onComplete:()->Void)
    {
        flickering = true;

        if (menuLayer == null)
        {
            menuLayer = anim.curSymbol.timeline.get("Menu");
            subMenuLayer = anim.curSymbol.timeline.get("Submenu");
        }
        FlxFlicker.flicker(menuObject, 1, 0.1, true, true);
        FlxFlicker.flicker(subMenuObject, 1, 0.04, true, true, (_) ->
        {
            onComplete();
            flickering = false;
        });
    }
    public function transition()
    {
        anim.goToFrameLabel("Transition");
    }

}