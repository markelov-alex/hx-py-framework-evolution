package v7.lib.components;

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
	
	private var langManager = LangManager.getInstance();
	
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
		// Register langManager listeners here because we don't need it if there is no skin assigned
		langManager.currentLangChangeSignal.add(langManager_currentLangChangeSignalHandler);
		
		// Apply
		refreshLang();
		refreshCurrentLang();
	}

	override private function unassignSkin():Void
	{
		// Listeners
		langManager.currentLangChangeSignal.remove(langManager_currentLangChangeSignalHandler);

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
			langManager.currentLang = lang;
		}
	}

	private function refreshLang():Void
	{
		if (mc != null)
		{
			var frame = frameByLang.exists(lang) ? frameByLang[lang] : defaultFrame;
			mc.gotoAndStop(frame);
		}
	}
	
	private function refreshCurrentLang():Void
	{
		isChecked = langManager.currentLang == lang;
	}
	
	// Handlers

	private function langManager_currentLangChangeSignalHandler(currentLang:String):Void
	{
		refreshCurrentLang();
	}
}
