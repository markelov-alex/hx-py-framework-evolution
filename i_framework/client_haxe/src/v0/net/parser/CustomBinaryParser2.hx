package v0.net.parser;

import v0.net.parser.CustomBinaryParser as CustomBinaryParser0;

/**
 * CustomBinaryParser.
 * 
 * For both dresser and coloring games.
 */
class CustomBinaryParser2 extends CustomBinaryParser0
{
	// Settings

	// State
	
	// Init

//	public function new()
//	{
//		super();
//	}

	override private function init():Void
	{
		super.init();
		
		codeByString["goto"] = 55;
		codeByString["lobby"] = 60;
		codeByString["dresser1"] = 70;
		codeByString["dresser2"] = 71;
		codeByString["dresser3"] = 72;
		codeByString["coloring1"] = 80;
		codeByString["coloring2"] = 81;
		codeByString["coloring3"] = 82;
	}

	// Methods
	
}
