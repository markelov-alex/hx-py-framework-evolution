package v1.lib.components;

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
	
	public var lang(default, set):String;
	public function set_lang(value:String):String
	{
		if (lang != value)
		{
			lang = value;
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
		// Register LangManager listeners here because we don't need it if there is no skin assigned
		LangManager.currentLangChangeSignal.add(langManager_currentLangChangeSignalHandler);
		
		// Apply
		refreshLang();
		refreshCurrentLang();
	}

	override private function unassignSkin():Void
	{
		// Listeners
		LangManager.currentLangChangeSignal.remove(langManager_currentLangChangeSignalHandler);

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
			LangManager.currentLang = lang;
		}
	}

	private function refreshLang():Void
	{
		if (mc != null)
		{
			var frame = if (frameByLang.exists(lang)) frameByLang[lang] else defaultFrame;
			mc.gotoAndStop(frame);
		}
	}
	
	private function refreshCurrentLang():Void
	{
		isChecked = LangManager.currentLang == lang;
	}
	
	// Handlers

	private function langManager_currentLangChangeSignalHandler(currentLang:String):Void
	{
		refreshCurrentLang();
	}
}
