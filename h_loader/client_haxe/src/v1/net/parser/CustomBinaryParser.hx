package v1.net.parser;

import v0.net.parser.CustomBinaryParser as CustomBinaryParser0;

/**
 * CustomBinaryParser.
 * 
 * For both dresser and coloring games.
 */
class CustomBinaryParser extends CustomBinaryParser0
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
		
		codeByString["goto"] = 5;
		codeByString["lobby"] = 20;
		codeByString["dresser1"] = 30;
		codeByString["dresser2"] = 31;
		codeByString["dresser3"] = 32;
		codeByString["coloring1"] = 40;
		codeByString["coloring2"] = 41;
		codeByString["coloring3"] = 42;
	}

	// Methods
	
}
