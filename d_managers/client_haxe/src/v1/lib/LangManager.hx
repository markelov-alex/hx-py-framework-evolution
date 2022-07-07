package v1.lib;

/**
 * LangManager.
 * 
 */
class LangManager
{
	// Settings

	// State
	
	public static var isEnabled = true;
	public static var defaultLang:String = "en";
	public static var langs = ["en", "ru", "de"];
	public static var actualLangs(default, null) = langs;
	
	public static var dictByLang(default, set):Map<String, Map<String, String>> = [
		"en" => new Map(), "ru" => new Map(), "de" => new Map()];
	public static function set_dictByLang(value:Map<String, Map<String, String>>):Map<String, Map<String, String>>
	{
		if (dictByLang != value)
		{
			dictByLang = value;
			// Refresh
			actualLangs = if (langs != null) [for (l in langs) if (dictByLang.exists(l)) l] else [];
			currentDict = value[currentLang];
		}
		return value;
	}
	
	
	public static var currentLang(default, set):String = defaultLang;
	public static function set_currentLang(value:String):String
	{
		if (currentLang != value && dictByLang.exists(value))
		{
			currentLang = value;
			currentDict = dictByLang[value];
			// Dispatch
			currentLangChangeSignal.dispatch(value);
		}
		return value;
	}
	
	private static var currentDict:Map<String, String> = new Map();
	
	// Signals

	public static var currentLangChangeSignal(default, null) = new Signal<String>();

	// Methods

	public static function get(key:String):String
	{
		if (currentDict == null || key == null)
		{
			return key;
		}
		var value = currentDict[key];
		return if (value != null) value else key;
	}
}
