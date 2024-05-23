package;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.frames.FlxFramesCollection;
import haxe.extern.EitherType;
import flixel.FlxSprite;

typedef GraphicAsset = EitherType<FlxGraphicAsset, FlxFramesCollection>;

class FlxLayeredGroup extends FlxTypedSpriteGroup<FlxLayer>
{
	public function getLayerByName(name:String)
	{
		for (child in group.members)
		{
			if (child.name == name) return child;
		}

		return null;
	}
}
class FlxLayer extends FlxTypedSpriteGroup<FlxNamedSprite>
{
	public var name:String;
	public function getSpriteByName(name:String)
	{
		for (child in group.members)
		{
			if (child.name == name) return child;
		}

		return null;
	}
}
class FlxNamedSprite extends FlxSprite
{
	public var name:String;
	public function new(?name:String, X:Float, Y:Float, SimpleGraphic:GraphicAsset)
	{
		this.name = name;
		super(X, Y);

		if ((SimpleGraphic is FlxGraphicAsset))
			loadGraphic(SimpleGraphic);
		else if(SimpleGraphic != null)
			frames = SimpleGraphic;
	}
}