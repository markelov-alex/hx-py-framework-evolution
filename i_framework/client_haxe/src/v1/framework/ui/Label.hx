package v1.framework.ui;

import lime.text.UTF8String;
import openfl.text.TextField;

/**
 * Label.
 * 
 */
class Label extends Component
{
	// Settings

	// State
	
	private var textField:TextField;

	public var text(default, set):String;
	public function set_text(value:String):String
	{
		if (text != value)
		{
			text = value;
			refreshText();
		}
		return value;
	}
	public var actualText(default, null):String;
	
	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		// Parse
		textField = Std.downcast(skin, TextField);
		if (textField != null)
		{
			textField.mouseEnabled = false;
		}
		
		// Listeners
		lang.currentLangChangeSignal.add(lang_currentLangChangeSignalHandler);
		
		// Apply
		refreshText();
	}

	override private function unassignSkin():Void
	{
		// Listeners
		lang.currentLangChangeSignal.remove(lang_currentLangChangeSignalHandler);

		textField = null;
		
		super.unassignSkin();
	}

	private function refreshText():Void
	{
		actualText = lang.get(text);
		if (textField != null && actualText != null)
		{
			textField.text = new UTF8String(actualText);
		}
	}
	
	// Handlers

	private function lang_currentLangChangeSignalHandler(currentLang:String):Void
	{
		refreshText();
	}
}
