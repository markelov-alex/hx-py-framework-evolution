package v0.lib.components;

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
	
	private var langManager = LangManager.getInstance();
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
		langManager.currentLangChangeSignal.add(langManager_currentLangChangeSignalHandler);
		
		// Apply
		refreshText();
	}

	override private function unassignSkin():Void
	{
		// Listeners
		langManager.currentLangChangeSignal.remove(langManager_currentLangChangeSignalHandler);

		textField = null;
		
		super.unassignSkin();
	}

	private function refreshText():Void
	{
		actualText = langManager.get(text);
		if (textField != null && actualText != null)
		{
			textField.text = new UTF8String(actualText);
		}
	}
	
	// Handlers

	private function langManager_currentLangChangeSignalHandler(currentLang:String):Void
	{
		refreshText();
	}
}
