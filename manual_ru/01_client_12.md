# Эволюция игрового фреймворка. Клиент 12. Локализация

## LangManager

Нечто похожее на [AudioManager](01_client_11.md) у нас получается и с менеджером локализации LangManager. В нем только две основные функции: выбрать язык (свойство currentLang) и получить перевод (метод get()):

```haxe
class LangManager extends Base
{
    // Settings
    public var defaultAssetName = "lang";
    public var isEnabled = true;
    public var defaultLang:String = "en";
    public var langs = ["en", "ru", "de"];
    // State
    private var shared:SharedObject = SharedObject.getLocal("managers");
    private var resource:ResourceManager;
    public var actualLangs(default, null):Array<String>;
    public var dictByLang(default, set):Map<String, Map<String, String>> = new Map();
    public function set_dictByLang(value:Map<String, Map<String, String>>):Map<String, Map<String, String>>
    {
        if (dictByLang != value)
        {
            dictByLang = value;
            // Refresh
            refreshData();
        }
        return value;
    }
    public var currentLang(default, set):String;
    public function set_currentLang(value:String):String
    {
        if (currentLang != value) // && (currentLang == null || dictByLang.exists(value)))
        {
            currentLang = value;
            shared.data.currentLang = value;
            //shared.flush();
            refreshData();
            // LangManager should be enabled for all labels to update their texts
            if (isEnabled)
            {
                // Dispatch
                currentLangChangeSignal.dispatch(value);
            }
        }
        return value;
    }
    private var currentDict:Map<String, String> = new Map();
    public var currentLangChangeSignal(default, null) = new Signal<String>();

    public function new()
    {
        super();
        // Default
        if (currentLang == null)
        {
            currentLang = defaultLang;
        }
        actualLangs = langs;
    }
    public function load(assetName:String=null):Void
    {
        if (assetName == null)
        {
            assetName = defaultAssetName;
        }

        // Get/load data
        Log.debug('Load: $assetName');
        var data = resource.getData(assetName);
        if (data != null)
        {
            // Set up manager and convert dict Objects -> lookup Maps
            var dictByLang = this.dictByLang;
            for (name in Reflect.fields(data))
            {
                var value:Dynamic = Reflect.getProperty(data, name);
                // Set up manager
                if (Reflect.hasField(this, name))
                {
                    Reflect.setProperty(this, name, value);
                    continue;
                }
                // Update lang lookup
                var lang = name;
                var dict = dictByLang[lang];
                if (dict == null)
                {
                    dict = dictByLang[lang] = new Map();
                }
                for (key in Reflect.fields(value))
                {
                    try
                    {
                        dict[key] = Reflect.getProperty(value, key);
                    }
                    catch (e:Exception)
                    {
                        Log.error("Unexpected data while parsing in LangManager.load()! " + e.details());
                        continue;
                    }
                }
                dictByLang[lang] = dict;
            }
            refreshData();
        }
    }
    public function loadPrevious():Void
    {
        if (shared.data.currentLang != null)
        {
            currentLang = shared.data.currentLang;
        }
        else
        {
            // Initialize shared.data
            shared.data.currentLang = currentLang;
            //shared.flush();
        }
    }
    private function refreshData():Void
    {
        actualLangs = if (langs != null) [for (l in langs) if (dictByLang.exists(l)) l] else [];
        currentDict = dictByLang[currentLang];
    }
    public function get(key:String):String
    {
        if (currentDict == null || key == null)
        {
            return key;
        }
        var value = currentDict[key];
        return if (value != null) value else key;
    }
}
```

Тут мы сразу сделали менеджер и с конфигурированием из файла, и с сохранением настроек в локальном хранилище. Хоть переводы можно задать и из кода (свойство dictByLang), но делать это в файле гораздо удобнее. С помощью файла "lang.yml" можно также настроить такие свойства менеджера, как язык по умолчанию (currentLang) и список доступных языков (langs):

```yaml
currentLang: en
langs = ["en", "ru", "de"]
en:
    "@menu_title": Managers
    Dressing: Dress Up
ru:
    "@menu_title": Менеджеры
    Dressing: Одевалка
    "Sound volume:": "Громкость звука:"
    "Music volume:": "Громкость музыки:"
```

Как видим, в качестве ключей для строк можно использовать сами строки, как они задаются в коде (пример: "Dressing"). Если нам нужно изменить оригинальную надпись (например, исправить "Dressing" на "Dress Up"), то нам совсем не обязательно для этого лезть в код. Достаточно выполнить подстановку в словаре на языке оригинала. Получится как бы перевод с английского на английский или с русского на русский.

Это хорошо работает для коротких строк, но для больших — может оказаться удобнее использовать ключ в явном виде. Чтобы визуально отделять ключи от строк, можно в начало добавлять какой-нибудь специальный символ, который редко используется в текстах, например, "@". Это может быть любой символ, потому что для программы это остается такой же обычной строкой, как и все прочие.

Использование менеджера в коде проще простого:

```haxe
class Label extends Component
{
    // State
    private var lang = LangManager.getInstance();

    override private function assignSkin():Void
    {
        //...
        lang.currentLangChangeSignal.add(lang_currentLangChangeSignalHandler);
    }
    override private function unassignSkin():Void
    {
        lang.currentLangChangeSignal.remove(lang_currentLangChangeSignalHandler);
        //...
    }
    private function refreshText():Void
    {
        actualText = lang.get(text);
        //...
    }
    private function lang_currentLangChangeSignalHandler(currentLang:String):Void
    {
        refreshText();
    }
}
```

А так как Label используется нами для всех текстовых полей (ведь так?), то добавив в него всего 9 строк кода, мы внедрили поддержку разных языков во всем приложении. Вот так просто.

Для переключения языков будем использовать специализированный RadioButton — LangButton:

```haxe
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
    private var lang = LangManager.getInstance();

    override private function assignSkin():Void
    {
        super.assignSkin();
        lang.currentLangChangeSignal.add(langManager_currentLangChangeSignalHandler);
        // Apply
        refreshLang();
        refreshCurrentLang();
    }
    override private function unassignSkin():Void
    {
        lang.currentLangChangeSignal.remove(langManager_currentLangChangeSignalHandler);
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
            var frame = if (frameByLang.exists(language)) frameByLang[language] else defaultFrame;
            mc.gotoAndStop(frame);
        }
    }
    private function refreshCurrentLang():Void
    {
        isChecked = lang.currentLang == language;
    }
    private function langManager_currentLangChangeSignalHandler(currentLang:String):Void
    {
        refreshCurrentLang();
    }
}
```

Скин для всех кнопок может быть одинаковым — это мувиклип, каждый кадр которого соответствует определенному языку (обычно показывается в виде флага страны). А чтобы отличать нажатое состояние от ненажатого, изменяется прозрачность кнопки.

Набор поддерживаемых языков может меняться, поэтому мы создадим компонент для всей языковой панели, которая будет скрывать лишние кнопки:

```haxe
class LangPanel extends Component
{
    // Settings
    public var langButtonPathPrefix = "langButton";
    public var align = "right";
    // State
    private var lang = LangManager.getInstance();
    public var language(get, set):String;
    public function get_language():String
    {
        return lang != null ? lang.currentLang : null;
    }
    public function set_language(value:String):String
    {
        return lang != null ? (lang.currentLang = value) : null;
    }

    override private function assignSkin():Void
    {
        super.assignSkin();
        // Create lang buttons according to given buttons in skin
        var langNames = lang.actualLangs;
        var buttonPaths = resolveSkinPathPrefix(langButtonPathPrefix);
        var hideCount = buttonPaths.length - langNames.length;
        if (hideCount < 0)
        {
            hideCount = 0;
        }
        var isAlignRight = align == "right";
        for (i in 0...buttonPaths.length)
        {
            var button:LangButton = createComponent(LangButton);
            button.skinPath = buttonPaths[i];
            button.language = langNames[i - hideCount];
            button.visible = !isAlignRight || i >= hideCount;
            addChild(button);
        }
    }
}
```

Так мы в приложении создаем только один компонент (LangPanel), а он уже подхватывает все существующие в текущей графике кнопки, скрывает все лишние, а для остальных настраивает язык в том же порядке, в каком языки указаны в ```LangManager.actualLangs```.

Можно пойти дальше и создать панель вообще для всех настроек: и аудио, и языков:

```haxe
class SettingsPanel extends Component
{
    // Settings
    public var soundVolumeLabelPath = "soundVolumeLabel";
    public var musicVolumeLabelPath = "musicVolumeLabel";
    // State
    private var soundToggleButton:SoundToggleButton;
    private var musicToggleButton:MusicToggleButton;
    private var soundVolumeSlider:SoundVolumeSlider;
    private var musicVolumeSlider:MusicVolumeSlider;
    private var soundVolumeLabel:Label;
    private var musicVolumeLabel:Label;
    private var langPanel:LangPanel;

    public function new()
    {
        super();

        soundToggleButton = new SoundToggleButton();
        addChild(soundToggleButton);
        musicToggleButton = new MusicToggleButton();
        addChild(musicToggleButton);
        soundVolumeSlider = new SoundVolumeSlider();
        addChild(soundVolumeSlider);
        musicVolumeSlider = new MusicVolumeSlider();
        addChild(musicVolumeSlider);

        // Note: If you wish to change label texts, it's better to do
        // that in lang.yml than creating special text setters
        soundVolumeLabel = new Label();
        soundVolumeLabel.skinPath = soundVolumeLabelPath;
        soundVolumeLabel.text = "Sound volume:";
        addChild(soundVolumeLabel);
        musicVolumeLabel = new Label();
        musicVolumeLabel.skinPath = musicVolumeLabelPath;
        musicVolumeLabel.text = "Music volume:";
        addChild(musicVolumeLabel);

        langPanel = new LangPanel();
        langPanel.skinPath = "langPanel";
        addChild(langPanel);
    }
}
```

Так как skinPath задается для всех специальных кнопок по умолчанию, то тут нам не нужно этого делать.

Менеджеры в сочетании со специальным компонентами, с ними работающими, полностью берут на себя такие обыкновенные для всех игр, как звуки и локализацию, освобождая для нас время на создание действительно уникальных вещей.

## Application

С учетом всех менеджеров, которые добавили в последнее время, Main-класс принимает примерно такой вид:

```haxe
class Main extends Sprite
{
    public function new()
    {
        super();
        var audio = AudioManager.getInstance();
        var lang = LangManager.getInstance();
        audio.load();
        lang.load();
        audio.loadPrevious();
        lang.loadPrevious();
        var screens = new Screens();
        screens.skin = this;
        screens.open(Menu);
    }
}
```

Так как все шаги в нем становятся достаточно стандартными для всех приложений, то его содержимое можно уже вынести в библиотеку (Extract class refactoring) под в виде класса Application:

```haxe
class Application extends Sprite
{
    public function new()
    {
        super();
        var audio = AudioManager.getInstance();
        var lang = LangManager.getInstance();
        audio.load();
        lang.load();
        audio.loadPrevious();
        lang.loadPrevious();
        var screens = new Screens();
        screens.skin = this;
        screens.open(Menu);
    }
}
class Main extends Application
{
}
```

Получившаяся библиотечка уже неплохое подспорье для профессиональной работы, и может вполне именоваться фреймворком, или каркасом. Концепция фреймворка предполагает, что всякую повторяющуюся функциональность всегда можно выделить в отдельный компонент и использовать повторно в других проектах. Фреймворк — это скелет, а компоненты — мышцы и органы, которые к нему крепятся. Какие органы мы прикрепим, такое приложение и получится. Дальше мы рассмотрим, как настраивать и подменять компоненты их улучшенными версиями.

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/d_managers/client_haxe/src/)


[< Назад](01_client_11.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](01_client_13.md)
