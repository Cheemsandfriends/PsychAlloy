package;

import flxanimate.animate.FlxLayer;
import openfl.filters.GlowFilter;
import flxanimate.FlxAnimate;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.FlxState;
import flixel.FlxSprite;

enum HandState
{
    LIFTING;
    IDLE;
    PRESSING;
    CREDITS;
}
class HandSprite extends FlxAnimate 
{
    var pressIndex:Int;
    var name:String;

    var _specialAnim(get, never):Bool;
    public var state(default, set):HandState;
    public var onPress(get, set):()->Void;
    var scripts:FlxLayer;

    public function new(X:Float = 0, Y:Float = 0)
    {
        super(X, Y, Paths.getTextureAtlas('mainmenu/hand'));
        antialiasing = ClientPrefs.globalAntialiasing;
        
        name = "PointerHand";
        
        state = LIFTING;
        scripts = anim.curSymbol.timeline.get(0);
        
        scripts.get("CREDITS").add(() -> anim.goToFrameLabel("PRE-IDLE"));
        scripts.get("IDLE").add(() -> anim.pause());
    }

    function get__specialAnim()
    {
        return [LIFTING, IDLE, PRESSING, null].indexOf(state) == -1;
    }
    function get_onPress()
    {
        return cast scripts.get("PRESSED").callbacks[0];
    }

    function set_onPress(value:()->Void)
    {
        return cast scripts.get("PRESSED").callbacks[0] = value;
    }

    function set_state(value:HandState)
    {
        if (value == state) return value;

        anim.pause();
        state = value;
        anim.framerate = 20;
        if (_specialAnim)
        {
            anim.framerate = anim.metadata.frameRate;
            anim.getFrameLabel("PRESSED " + value.getName()).callbacks = anim.getFrameLabel("PRESSED").callbacks;
        }

        anim.goToFrameLabel(value.getName());
        
        anim.resume();
        return value;
    }
}