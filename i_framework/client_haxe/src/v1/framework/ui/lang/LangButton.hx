package v1.framework.ui.lang;

/**
 * LangButton.
 * 
 */
class LangButton extends RadioButton
{
	// Settings
	
	public var defaultFrame = 1;
	public var frameByLang = ["en" => 1, "ru" => 2, "de" => 3];

	// State
	
	public var language(default, set):String;
	public function set_language(value:String):String
	{
		if (language != value)
		{
			language = value;
			refreshLang();
		}
		return value;
	}

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		// Listeners
		// Register lang listeners here because we don't need it if there is no skin assigned
		lang.currentLangChangeSignal.add(lang_currentLangChangeSignalHandler);
		
		// Apply
		refreshLang();
		refreshCurrentLang();
	}

	override private function unassignSkin():Void
	{
		// Listeners
		lang.currentLangChangeSignal.remove(lang_currentLangChangeSignalHandler);

		super.unassignSkin();
	}

	override private function refreshChecked():Void
	{
		super.refreshChecked();
		
		if (skin != null)
		{
			skin.alpha = if (isChecked) 1 else .7;
		}
		if (isChecked)
		{
			lang.currentLang = language;
		}
	}

	private function refreshLang():Void
	{
		if (mc != null)
		{
			var frame = frameByLang.exists(language) ? frameByLang[language] : defaultFrame;
			mc.gotoAndStop(frame);
		}
	}
	
	private function refreshCurrentLang():Void
	{
		isChecked = lang.currentLang == language;
	}
	
	// Handlers

	private function lang_currentLangChangeSignalHandler(currentLang:String):Void
	{
		refreshCurrentLang();
	}
}
