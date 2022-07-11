# Эволюция игрового фреймворка. Клиент 13. Инверсия управления
## IoC

К данному моменту основа фреймворка уже готова, и на нем вполне можно разрабатывать игры. При этом игры будут получаться во вполне себе обобщенном виде. То есть, сделав типичную игру для выбранного жанра, мы можем взять ее за основу всех других аналогичных игр. Можно даже после небольшого рефакторинга вынести ее в отдельную игровую библиотечку и штамповать с ее помощью многочисленных клонов. Если в клоне меняется только графика и звуки (assets), то весь код проекта вообще будет состоять из одного класса Main.

Давайте проверим эту мысль на примере игр-одевалок и нашего класса Dresser и посмотрим, с какими трудностями мы столкнемся.

Вынесем классы Dresser, Menu и остальные от них зависимые в условную библиотечку dresser. Тогда код простейшего проекта будет состоять всего из одного класса Main (ведь ни один проект не может существовать совсем без классов):

```haxe
class Main extends Application
{
}
```

Простой экран меню состоит из панели настроек и кнопки входа в игру:

```haxe
class Menu extends Component
{
    // State
    private var gameButton:Button;
    private var settingsPanel:SettingsPanel;
    private var screens = Screens.getInstance();

    public function new()
    {
        super();
        // Default
        assetName = "dresser:AssetMenuScreen";

        gameButton = new Button();
        gameButton.skinPath = "gameButton";
        gameButton.clickSignal.add(gameButton_clickSignalHandler);
        addChild(gameButton);

        settingsPanel = new SettingsPanel();
        settingsPanel.skinPath = "settingsPanel";
        addChild(settingsPanel);
    }
    private function gameButton_clickSignalHandler(target:Button):Void
    {
        screens.open(Dresser);
    }
}
```

Но допустим, в fla-файле графика для радиокнопок переключения языков находится не в отдельном мувиклипе langPanel, а прямо в settingsPanel. Тогда нам нужно изменить в коде свойство skinPath компонента langPanel с "langPanel" на "". Посмотрим, сколько классов затронет такая простейшая перемена.

Первое, нам нужно переопределить сам класс SettingsPanel:

```haxe
class SettingsPanel2 extends SettingsPanel
{
    public function new()
    {
        super();
        langPanel.skinPath = "";
    }
}
```

Потом нам нужно подставить новый класс SettingsPanel2 вместо старого SettingsPanel. Для этого придется сделать кое-какие изменения в саму библиотеку. А именно — добавить типы внутренних компонентов в настройки класса: gameButtonType, settingsPanelType.

```haxe
class Menu extends Component
{
    // Settings
    public var gameButtonType = Button;
    public var settingsPanelType = SettingsPanel;
    // State
    //...

    public function new()
    {
        super();
        // Default
        assetName = "dresser:AssetMenuScreen";
        init();
    }
    private function init():Void
    {
        gameButton = Type.createInstance(gameButtonType, []);
        //...
        settingsPanel = Type.createInstance(settingsPanelType, []);
        //...
    }
    //...
}
class Menu2 extends Menu
{
    override private function init():Void
    {
        settingsPanelType = SettingsPanel2;
        super.init();
    }
}
```

Тут нам пришлось учесть еще такой момент: как мы в подклассе сможем подменить дефолтное значение settingsPanelType нужным нам классом? Прежде всего, это нужно сделать в конструкторе, то есть до того, как это свойство будет использовано. Если сделать это до вызова super(), то super() перетрет новые значения дефолтными: ```public var settingsPanelType = SettingsPanel;```. Если после — то это будет слишком поздно: компоненты уже будут созданы по дефолтным классам.

По этой причине мы больше не можем создавать вложенные компоненты в конструкторе. Для этих целей выделяется отдельный метод init(). Свойства, измененные перед ```super.init()```, не будут ни затерты, ни пропущены (см. ```settingsPanelType = SettingsPanel2;```).

Далее, нужно подменить Menu на Menu2. Эта операция также потребует небольшого вмешательства в библиотеку. А именно в класс Application:

```haxe
class Application extends Sprite
{
    private var screens:Screens;
    public function new()
    {
        super();
        // Init
        var audio = AudioManager.getInstance();
        var lang = LangManager.getInstance();
        audio.load();
        lang.load();
        audio.loadPrevious();
        lang.loadPrevious();
        screens = new Screens();
        screens.skin = this;
        // Start
        start();
    }
    private function start():Void
    {
        screens.open(Menu);
    }
}
class Main extends Application
{
    override private function start():Void
    {
        screens.open(Menu2);
    }
}
class Dresser2 extends Dresser
{
    override private function closeButton_clickHandler(target:Button):Void
    {
        screens.open(Menu2);
    }
}
class Menu2 extends Menu
{
    //...
    override private function gameButton_clickSignalHandler(target:Button):Void
    {
        screens.open(Dresser2);
    }
}
```

В итоге для изменения одной строчки нам потребовалось переопределить целых 4 класса, чтобы до нее добраться — то есть всю цепочку родителей вплоть до Main. И это еще в таком простом приложении. Ясно, что это никуда не годится, и нужно придумать для подобной ситуации решение получше.

Давайте для начала просто пофантазируем, какое решение было бы тут идеальным для нас? А оно такое: мы создаем подкласс SettingsPanel2 и говорим системе, чтобы она отныне использовала его всегда вместо SettingsPanel.

```haxe
class SettingsPanel2 extends SettingsPanel
{
    public function new()
    {
        super();
        langPanel.skinPath = "";
    }
}
class Main extends Application
{
    override private function start():Void
    {
        registerSubstitution(SettingsPanel, SettingsPanel2);
        super.start();
    }
}
```

Да, тут лишнего кода получается гораздо меньше. Точнее, его вовсе нет. Но не слишком ли это оптимистично с нашей стороны: можно ли все это реализовать?

Можно. И к тому же это несложно. Но для этого нам придется изменить механизм инстанцирования (создания экземпляров) классов. Все объекты компонентов отныне должны создаваться через метод createComponent(). Так как он находится в базовом классе Component, то он доступен для всех компонентов:

```haxe
class Menu extends Component
{
    // Settings
    public var gameButtonType = Button;
    public var settingsPanelType = SettingsPanel;
    // State
    //...

    public function new()
    {
        super();
        // Default
        assetName = "dresser:AssetMenuScreen";
        init();
    }
    private function init():Void
    {
        gameButton = createComponent(gameButtonType);
        //...
        settingsPanel = createComponent(settingsPanelType);
        //...
    }
    //...
}
class Component
{
    //...
    private function createComponent<T>(type:Class<T>):T
    {
        // return ???;
    }
}
```

Внутри метода createComponent() для полученного типа (type) ищется замена, по которой и создается экземпляр компонента. Замена регистрируется функцией Application.registerSubstitution(). Если замены нет, то используется переданный тип.

(Заметим, что gameButtonType и settingsPanelType можно было бы убрать и вызывать просто createComponent(Button) вместо createComponent(gameButtonType). Но тогда, подменяя класс Button, мы автоматически меняли бы все кнопки в проекте, а не только в меню, как нам нужно. Поэтому использование типов в настройках (```xxxType:Class<Component>```) по-прежнему полезно. Данные свойства позволяют нам делать точечные подмены в нужных классах.)

Итак, чтобы создать компонент, нам нужен словарь всех подмен типов, а он пока находится там же, где и метод ```registerSubstitution()``` — в Application. Получается, что в каждый компонент при создании должна передаваться по цепочке ссылка на экземпляр Application. Но из всего Application нам только и нужен, что словарь подмен. Поэтому разумнее будет выделить класс, который будет хранить в себе все подмены и создавать новые объекты по переданному ему типу. Такой класс называется IoC-контейнер. IoC означает "инверсия управления" (Inversion of Control). Чтобы легче было понять, что такое IoC, рассмотрим для начала код IoC-контейнера и то, как он будет использоваться:

```haxe
class IoC
{
    // Static
    private static var instance:IoC;
    public static function getInstance():IoC
    {
        if (instance == null)
        {
            instance = new IoC();
        }
        return instance;
    }
    // Settings
    private var realTypeByTypeName:Map<String, Class<Dynamic>> = new Map();

    public function new()
    {
        if (instance != null)
        {
            throw new Exception("Singleton class can have only one instance!");
        }
        instance = this;
    }
    public function register<T>(type:Class<T>, realType:Class<T>):Void
    {
        var typeName = Type.getClassName(type);
        realTypeByTypeName[typeName] = realType;
    }
    public function create<T>(type:Class<T>, ?args:Array<Dynamic>):T
    {
        if (type == null)
        {
            return null;
        }
        var typeName = Type.getClassName(type);
        var realType = realTypeByTypeName[typeName];
        if (realType == null)
        {
            realType = type;
        }
        return Type.createInstance(realType, args);
    }
}

// Using:
class Application
{
    private var ioc = IoC.getInstance();
    //...
}
class Main extends Application
{
    override private function start():Void
    {
        // Configure app
        ioc.register(SettingsPanel, SettingsPanel2);
        // Start app
        super.start();
    }
}
class Component
{
    private var ioc = IoC.getInstance();
    //...
    private function createComponent<T>(type:Class<T>):T
    {
        return ioc.create(type);
    }
}
class SettingsPanel extends Component
{
    //...
    public function new()
    {
        super();
        // was: soundToggleButton = new SoundToggleButton();
        soundToggleButton = createComponent(SoundToggleButton);
        addChild(soundToggleButton);
        musicToggleButton = createComponent(MusicToggleButton);
        addChild(musicToggleButton);
        //...
        langPanel = createComponent(LangPanel);
        langPanel.skinPath = "langPanel";
        addChild(langPanel);
    }
}
```

Чтобы обеспечить глобальный доступ к IoC-контейнеру, мы его сделали синглтоном, как и другие менеджера. Метод registerSubstitution() был для краткости переименован в register(). Все экземпляры классов теперь создаются не через Type.createInstance(), а через IoC.getInstance().create(). Именно в create() и осуществляется подстановка реального типа вместо общего, если он есть. Если нет, используется общий.

Теперь немного о том, что такое инверсия управления (IoC).

В простом случае разработчик пишет полностью всю программу, а значит, он и управляет выполнением кода. Но если в коде вызываются функции фреймворка, то мы как бы передаем в этом месте управление фреймворку. В особенности, если результат выполнения этих функций зависит от того, как этот фреймворк был предварительно настроен. Получается, что уже не программист управляет выполнением программы, не сами классы этой программы, а фреймворк. Управление программой инвертировалось. А сам такой прием оформился в один из шаблонов проектирования, который называется инверсия управления.

Это была инверсия управления в общем виде. Но она имеет и разные частные случаи. Например, IoC можно также применить к управлению зависимостями. Данная техника называется внедрением зависимостей (Dependency Injection, DI). Суть ее состоит в том, что класс не отвечает сам за то, какие реализации объектов ему использовать. За это отвечает класс-инжектор (Injector), он же IoC-контейнер. Принимающая сторона при этом называется клиентом, а внедряемый объект сервис (данная терминология в этом контексте будет применяться только здесь; в дальнейшем слова клиент и сервис будут означать совершенно другие вещи).

В классической реализации DI клиент полностью пассивен. Он только предоставляет параметры конструктора и свойства, а инжектор сам в автоматическом режиме наполняет их сервисами, т.е. объектами нужных классов. Но так как реализация этого требует использования рефлексии — получения подробной информации о классе, его свойствах, методах, используемых типах — что достаточно сложно и затратно по производительности, то мы немного упростим нашу реализацию данного паттерна. Наши клиенты сами будут запрашивать IoC-контейнер на нужные им объекты.

Поэтому тут инверсия управления получается частичная: фреймворку поручается только создание объекта, а за заполнение собственных свойств отвечает сам объект. Такая реализация IoC еще и более очевидная, тогда как классическая инжекция зависимостей с непривычки воспринимается всеми как магия: не понятно, откуда в свойствах появляются значения, если нигде в коде они ни разу не присваиваются.

Типичным для IoC-фреймворков является также настройка через внешние конфигурационные файлы. Раз уж мы создаем все объекты в одно месте, то почему бы их тут же все и не настраивать? Так можно переделывать приложение, даже не перекомпилируюя его. Для нашего конкретного случая конфиг-файл может быть таким:

```yaml
LangPanel:
    skinPath: ""
```

или таким:

```yaml
SettingsPanel:
    langPanel.skinPath: ""
```

или таким:

```yaml
Menu:
    settingsPanel.langPanel.skinPath: ""
```

То есть мы решили задачу вообще без привлечения новых классов. Поэтому с введением конфигов подмену типов можно использовать только тогда, когда действительно меняется функционал в классе, а не его настройки.

Что касается реализации конфигов в IoC — так как у нас уже есть некоторый опыт использования конфигурационных файлов в других менеджерах, то и тут мы, наверняка, неплохо справимся.

```haxe
class IoC
{
    // Settings
    public var defaultAssetName = "config.yml";
    //...
    // State
    private var configByName:Map<String, Map<String, Dynamic>> = new Map();
    private var configNamesByTypeName:Map<String, Array<String>> = new Map(); // (Cache)
    //...
    public function load(assetName:String=null):Void
    {
        if (assetName == null)
        {
            assetName = defaultAssetName;
        }
        // Get/load data
        var data = ResourceManager.getInstance().getData(assetName);
        if (data == null)
        {
            return;
        }
        // Apply
        // (Fill up configByName)
        for (key in Reflect.fields(data))
        {
            var configData:Dynamic = Reflect.getProperty(data, key);
            var config:Map<String, Dynamic> = configByName[key];
            if (config == null)
            {
                configByName[key] = config = new Map();
            }
            // (Update config item)
            for (path in Reflect.fields(configData))
            {
                config[path] = Reflect.getProperty(configData, name);
            }
        }
    }
    public function create<T>(type:Class<T>):T
    {
        if (type == null)
        {
            return null;
        }
        var typeName = Type.getClassName(type);
        var realType = realTypeByTypeName[typeName];
        var result = Type.createInstance(realType != null ? realType : type, []);
        applyConfig(result, typeName, realType);
        return result;
    }
    private function applyConfig<T>(result:T, typeName:String, ?realType:Class<Dynamic>):Void
    {
        // Get all possible configNames
        var typeName = Type.getClassName(type);
        var configNames = configNamesByTypeName[typeName];
        if (configNames == null)
        {
            // type=game.Button2 which substitutes e.g. ui.Button ->
            // ["Button2", "game.Button2", "Button", "ui.Button", ]
            var realType = realTypeByTypeName[typeName];
            var realTypeName:String = realType != null ? Type.getClassName(realType) : null;
            var index = typeName.lastIndexOf(".");
            var typeLastName = index != -1 ? typeName.substring(index + 1) : null;
            index = realTypeName != null ? realTypeName.lastIndexOf(".") : -1;
            var realTypeLastName = index != -1 ? realTypeName.substring(index + 1) : null;
            typeLastName = typeLastName != realTypeLastName ? typeLastName : null;
            configNames = [typeLastName, typeName, realTypeLastName, realTypeName];
            configNames = [for (cn in configNames) if (cn != null) cn];
            // (Cache)
            configNamesByTypeName[typeName] = configNames;
        }
        // Apply configs
        for (name in configNames)
        {
            var config = configByName[name];
            if (config != null)
            {
                for (path => value in config)
                {
                    // For path like "settingsPanel.langPanel.skinPath"
                    ReflectUtil.setPath(result, path, value);
                }
            }
        }
        return result;
    }
}
class ReflectUtil
{
    public static function setPath(instance:Dynamic, path:String, value:Dynamic, isSkipNull=false):Bool
    {
        if (instance == null || path == null || path == "")
        {
            return false;
        }
        // Parse path
        var fields = path.split(".");
        var lastField = fields.pop();
        // Get target
        var target = instance;
        for (field in fields)
        {
            if (!Reflect.hasField(target, field))
            {
                Log.warn('Instance: $target doesn\'t have field: $field, ' +
                    'so value: $value cannot be set into $instance.$path!');
                return false;
            }
            target = Reflect.getProperty(target, field);
        }
        if (target == null && isSkipNull)
        {
            return false;
        }
        // Set
        var field = lastField;
        if (!Reflect.hasField(instance, field))
        {
            Log.warn('Instance: $target doesn\'t have field: $field, ' +
                'so value: $value cannot be set into $instance.$path!');
            return false;
        }
        else
        {
            Reflect.setProperty(target, field, value);
        }
        return true;
    }
}
```

Заметим, что при загрузке файла конфиги для каждого типа не перезаписываются, а обновляются. Поэтому возможно загружать несколько разных конфигурационных файлов, которые будут лишь дополнять друг друга.

Далее, при создании нового экземпляра ищутся конфиги для всех возможных имен данного типа: и данного, и подставляемого вместо него реального типа; полная версия (с пакетами) и короткая — только с именем класса. Это позволяет нам не перечислять все пакеты в config.yml, а указывать только одно имя класса. Также нам не нужно дублировать конфиг для подменяемых типов. Все это делает файл конфигурации более лаконичным и красивым.

Также во избежание ненужного дублирования имеет смысл сразу создать механизм наследования конфигов. Суть его простая: если в объекте есть поле super, то из этого родительского объекта копируются все поля, которых нет в данном объекте. Если и в родительском есть super, то процесс повторяется рекурсивно вплоть до самого базового объекта.

```yaml
LangPanel:
    skinPath: ""
CustomLangPanel:
    super: LangPanel  # Copy properties from "LangPanel"
    assetName: AssetCustomLangPanel  # Property added
CustomLangPanel2:
    super: LangPanel
    skinPath: "some"  # Property overwritten: "" -> "some"
```

Вообще-то, заранее придумывать функционал, когда необходимость в нем еще не проявилась со всей очевидностью на практике, плохая идея. Многое, что кажется сначала нужным, на деле оказывается лишним. А время уже потрачено, и выбрасывать ненужный код из класса жалко. Но сейчас это не тот случай. Наследование конфигов — вещь хорошая и уже успела показать себя на деле с хорошей стороны. Но с точки зрения текста, мы просто чудесным образом заглянули в будущее.

Реализовать наследование конфигов можно двумя способами: применить все super один раз при загрузке или каждый раз при создании нового объекта. Первый вариант, очевидно, менее затратен, а потому разумнее:

```haxe
class IoC
{
    //...
    public function load(assetName:String=null):Void
    {
        //...
        // Resolve supers
        // (Supers work only within a file)
        // (Resolve here once to do not resolve them each time on create() called)
        for (config in configByName)
        {
            if (config["super"] != null)
            {
                applySuperConfig(config, configByName);
            }
        }
    }
    private static function applySuperConfig(config:Map<String, Dynamic>, configByName:Map<String, Map<String, Dynamic>>):Void
    {
        if (config == null || config["super"] == null || configByName == null)
        {
            return;
        }
        var superConfig = configByName[config["super"]];
        // Remove property "super" as it's only utilitary
        config.remove("super"); // Place here to prevent infinite recursion
        // Resolve supers recursively
        if (superConfig["super"] != null)
        {
            applySuperConfig(superConfig, configByName);
        }
        // Apply
        for (key => value in superConfig)
        {
            // Add only those properties, that haven't been already set
            if (config[key] == null)
            {
                config[key] = value;
            }
        }
    }
}
```

Видно, что один родительский конфиг может, в свою очередь, наследоваться от другого конфига, и так до бесконечности. В коде это сделано с помощью рекурсии. Свойства берутся у родителей только тогда, когда они не заданы в дочерних конфигах, так как данные последних более актуальны.

Настраивать или подменять классы можно не только для компонентов, но и для любых других типов, в том числе менеджеров. Для этого достаточно повсюду использовать метод ```IoC.getInstance().create();``` вместо явного вызова конструктора:

```haxe
// Same for other managers
class AudioManager
{
    // Static
    private static var instance:AudioManager;
    public static function getInstance():AudioManager
    {
        if (instance == null)
        {
            instance = IoC.getInstance().create(AudioManager);
        }
        return instance;
    }
    //...
}
```

IoC должен быть уже настроен к моменту создания менеджеров и компонентов, поэтому в Application ```ioc.load()``` вызывается раньше всех:

```haxe
class Application extends Sprite
{
    private var ioc:IoC;
    private var screens:Screens;
    public function new()
    {
        super();
        // Init
        ioc = IoC.getInstance();
        configureApp();
        ioc.load();
        var audio = AudioManager.getInstance();
        audio.load();
        var lang = LangManager.getInstance();
        lang.load();
        audio.loadPrevious();
        lang.loadPrevious();
        screens = new Screens();
        screens.skin = this;
        // Start
        start();
    }
    // Override to call ioc.register() for all needed substitutions
    private function configureApp():Void
    {
    }
    private function start():Void
    {
        screens.open(Menu);
    }
}
```

Итак, создав класс IoC и реализовав поддержку конфигов (config.yml) в нем, мы получили возможность легко и просто настраивать любой класс в приложении, не меняя ни одной строчки в коде. А если требуется расширить или изменить функционал класса, для которого нет настроек, то IoC предоставляет возможность подменять типы (register()). Это относительно небольшое улучшение делает процесс разработки на порядок комфортнее и быстрее.

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/d_managers/client_haxe/src/v3/)

[< Назад](01_client_12.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](01_client_14.md)
