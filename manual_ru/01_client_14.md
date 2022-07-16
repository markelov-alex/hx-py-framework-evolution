# Эволюция игрового фреймворка. Клиент 14. Сеанс одновременной игры
## MultiApplication

Классифицируя игры, мы обнаружили, что все игры делятся на две большие группы: пошаговые и реального времени. Последние требуют полного вовлечения игрока, так как там можно совершать действия все время. В первых — ходы пользователей чередуются, а потому пока один ходит, остальные вынуждены ждать.

Чтобы заполнить эту паузу некоторые игры позволяют запускать сразу несколько сессий и играть одновременно несколько партий. Особенно для этого подходят игры, в которых все состояние помещается на одном экране, так что опытному игроку можно с одного взгляда разобраться в ситуации и принять решение. К ним относятся шахматы, покер, крестики-нолики, в отличие от, скажем Цивилизации, где состояние игры распределено по карте, городам, дереву знаний и т.д. Шахматы практикуют сеанс одновременной игры и в офлайне, поэтому тут ничего нового не изобретается.

Получившийся к этому моменту версия фреймворка работает только для одной игры. Мы не можем загрузить в приложении несколько игр, потому что у нас используются повсюду синглтоны. Конечно, не страшно, если при смене языка в одной игре, он сменится и во всех остальных. А то, что игры не могут запустить одновременно несколько музыкальных треков — это даже в плюс. Но это уже не работает со скринами и не будет работать классами логики, которые также удобно сделать синглтонами: контроллерами, моделями, соединениями с сокет-сервером. Тут одновременная работа нескольких игр становится невозможной. А если мы захотим загружать и вовсе разные приложения с разной конфигурацией (config.yml, lang.yml, audio.yml), то нужно еще разделать и синглтоны менеджеров. Вот почему обычно рекомендуется избегать использования синглтонов.

Поэтому основной задачей в этом материале будет избавиться от синглтонов. Но пока что создадим загрузчик для того, что есть, и посмотрим, как будут работать игры с одинаковыми скринами и менеджерами. Создадим приложение MultiApplication, которое будет загружать другие приложения. Будем менять количество запущенных одновременно приложений нажатием на кнопки цифровой клавиатуры (NumPad) от 0 до 9:

```haxe
class Main extends MultiApplication
{
    override private function init():Void
    {
        defaultAppClass = AppMain;
        super.init();
        stage.addEventListener(KeyboardEvent.KEY_UP, stage_keyUpHandler);
    }
    private function stage_keyUpHandler(event:KeyboardEvent):Void
    {
        // Change application count by numpad keys
        if (event.keyCode >= Keyboard.NUMPAD_0 && event.keyCode <= Keyboard.NUMPAD_9)
        {
            appCount = event.keyCode - Keyboard.NUMPAD_0;
        }
    }
}
class MultiApplication extends Application
{
    // Settings
    private var defaultAppClass:Class<Application>;
    // State
    public var appCount(default, set):Int = 1;
    public function set_appCount(value:Int):Int
    {
        if (appCount != value)
        {
            appCount = value;
            refreshApps();
        }
        return value;
    }
    private var apps:Array<Application> = [];
    private var appMatrix:Array<Array<Application>>;

    override private function init():Void
    {
        super.init();
        // Priority should be higher than for StageResizer to change Application's
        // stageWidth/Height before they'll be used in StageResizer.
        var priority = 3;
        stage.addEventListener(Event.RESIZE, stage_resizeHandler, false, priority);
        refreshApps();
    }
    override public function dispose():Void
    {
        stage.removeEventListener(Event.RESIZE, stage_resizeHandler);
        appCount = 0;

        super.dispose();
    }
    private function refreshApps():Void
    {
        var createCount = appCount - apps.length;
        if (createCount != 0)
        {
            Log.debug('Change appCount: ${apps.length} -> $appCount');
        }
        if (createCount == 0)
        {
            return;
        }
        // Create
        else if (createCount > 0)
        {
            for (i in 0...createCount)
            {
                var app = createApp(apps.length);
                apps.push(app);
            }
        }
        // Remove
        else
        {
            for (i in createCount...0)
            {
                var app = apps.pop();
                disposeApp(app);
            }
        }
        // Arrange applications in 2 dimensions
        appMatrix = arrayToMatrix(apps);
        // Affecting all StageResizers
        if (stage != null)
        {
            stage.dispatchEvent(new Event(Event.RESIZE));
        }
    }
    // Override to use index
    private function createApp(index:Int, ?appClass:Class<Application>, ?args:Array<Dynamic>):Application
    {
        if (appClass == null)
        {
            appClass = defaultAppClass;
        }
        if (args == null)
        {
            args = [];
        }
        Log.debug('Create application: $appClass');
        var app = Type.createInstance(appClass, args);
        addChild(app);
        return app;
    }
    private function disposeApp(app:Application):Void
    {
        if (app == null)
        {
            return;
        }
        Log.debug('Dispose application: $app');
        app.dispose();
        if (app.parent != null)
        {
            app.parent.removeChild(app);
        }
    }
    private function arrayToMatrix<T>(array:Array<T>, isPreferHorizontal=true):Array<Array<T>>
    {
        if (array == null)
        {
            return null;
        }
        if (array.length < 2)
        {
            return [array];
        }
        var squareSideCount = Math.ceil(Math.sqrt(array.length));
        var result = [];
        var i = 0;
        var row:Array<T> = null;
        for (item in array)
        {
            if (i == 0)
            {
                row = [];
                result.push(row);
            }
            row.push(item);
            i = i + 1 >= squareSideCount ? 0 : i + 1;
        }
        if (!isPreferHorizontal)
        {
            result = transposeMatrix(result);
        }
        return result;
    }
    private function rearrangeApps():Void
    {
        if (appMatrix == null)
        {
            return;
        }
        var rowCount = appMatrix.length;
        var colCount = rowCount > 0 ? appMatrix[0].length : 0;
        var appWidth = colCount > 0 ? stageWidth / colCount : 0;
        var appHeight = rowCount > 0 ? stageHeight / rowCount : 0;
        for (i in 0...appMatrix.length)
        {
            var row = appMatrix[i];
            var y = i * appHeight;
            for (j in 0...row.length)
            {
                var app:Application = row[j];
                app.x = j * appWidth;
                app.y = y;
                app.stageWidth = appWidth;
                app.stageHeight = appHeight;
            }
        }
    }
    private function stage_resizeHandler(event:Event):Void
    {
        rearrangeApps();
    }
}
```

Так как отдельные приложения больше не могут занимать всю сцену, весь экран, а вынуждены делить его со своими соседями, то для каждого из них в методе ```rearrangeApps()``` задается наряду с новыми координатами еще и новые размеры, в которые он должен вписываться. Для этого в базовый класс ```Application``` добавляются новые свойства stageWidth, stageHeight. Их StageResizer будет использовать при масштабировании. Ниже можно убедиться, что по умолчанию (то есть если они не заданы явно в MultiApplication) эти свойства возвращают размеры актуальной сцены (stage).

```haxe
class Application extends Sprite
{
    // State
    private var ioc:IoC;
    private var _stageWidth:Float = -1;
    @:isVar
    public var stageWidth(get, set):Float;
    public function get_stageWidth():Float
    {
        return _stageWidth <= 0 && stage != null ? stage.stageWidth : _stageWidth;
    }
    public function set_stageWidth(value:Float):Float
    {
        return _stageWidth = value;
    }
    private var _stageHeight:Float = -1;
    @:isVar
    public var stageHeight(get, set):Float;
    public function get_stageHeight():Float
    {
        return _stageHeight <= 0 && stage != null ? stage.stageHeight : _stageHeight;
    }
    public function set_stageHeight(value:Float):Float
    {
        return _stageHeight = value;
    }

    public function new()
    {
        super();
        if (stage != null)
        {
            init();
            start();
        }
        else
        {
            addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
        }
    }
    private function init():Void
    {
        ioc = IoC.getInstance();//?
        // First of all set up IoC (register all class substitution, change defaultAssetName)
        configureApp();
    }
    private function configureApp():Void
    {
    }
    private function start():Void
    {
    }
    public function dispose():Void
    {
    }
    private function addedToStageHandler(event:Event):Void
    {
        removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
        init();
        start();
    }
}
class StageResizer extends Component
{
    // State
    private var stage(default, set):Stage;
    private function set_stage(value:Stage):Stage
    {
        //...
    }
    private var application:Application; // New
    private function get_stageWidth():Float // New
    {
        return application != null ? application.stageWidth :
            (stage != null ? stage.stageWidth : 0);
    }
    private function get_stageHeight():Float // New
    {
        return application != null ? application.stageHeight :
            (stage != null ? stage.stageHeight : 0);
    }

    override private function assignSkin():Void
    {
        super.assignSkin();
        application = findSkinParentOfType(skin, Application); // New
        stage = skin.stage;
        skin.addEventListener(Event.ADDED_TO_STAGE, skin_addedToStageHandler);
        skin.addEventListener(Event.REMOVED_FROM_STAGE, skin_removedFromStageHandler);
    }
    override private function unassignSkin():Void
    {
        // Listeners
        skin.removeEventListener(Event.ADDED_TO_STAGE, skin_addedToStageHandler);
        skin.removeEventListener(Event.REMOVED_FROM_STAGE, skin_removedFromStageHandler);
        stage = null;
        application = null; // New
        super.unassignSkin();
    }
    private function findSkinParentOfType(skin:DisplayObject, type:Class<Dynamic>):DisplayObject // New
    {
        if (skin == null || skin.parent == null)
        {
            return null;
        }
        var parent = skin.parent;
        if (Std.isOfType(parent, type))
        {
            return parent;
        }
        return findSkinParentOfType(parent, type);
    }
    // Changes: stage.stageWidth/Height -> stageWidth/Height
    private function resize():Void
    {
        // Fit min
        skin.width = stageWidth;
        skin.scaleY = skin.scaleX;
        if (skin.height > stageHeight)
        {
            skin.height = stageHeight;
            skin.scaleX = skin.scaleY;
        }
        // Align center, considering skin's center is in top left corner
        skin.x = Math.round((stageWidth - skin.width) / 2);
        skin.y = Math.round((stageHeight - skin.height) / 2);
    }
    //...
}
```

Так как в MultiApplication обычно не нужны ни менеджеры, ни скрины, то все это выносится из Application в отдельный класс GameApplication. Так Application разделяется на два вида: MultiApplication — для загрузчиков, GameApplication — собственно, для игр.

```haxe
class GameApplication extends Application
{
    // Settings
    public var startScreenClass:Class<Component>;
    // State
    private var screens:Screens;

    override private function init():Void
    {
        super.init();
        ioc.load();
        var audio = AudioManager.getInstance();//?
        var lang = LangManager.getInstance();//?
        audio.load();
        lang.load();
        audio.loadPrevious();
        lang.loadPrevious();
        screens = Screens.getInstance();//?
        screens.skin = this;
    }
    override private function start():Void
    {
        super.start();
        screens.open(startScreenClass);
    }
    override public function dispose():Void
    {
        if (screens != null)
        {
            screens.dispose();
            screens = null;
        }
        super.dispose();
    }
}
// Used in Main (MultiApplication)
class AppMain extends GameApplication
{
    public function new()
    {
        super();
        startScreenClass = Menu;
    }
}
```

В процессе обобщения GameApplication мы вынесли из него также привязку к конкретному начальному скрину (Menu), заменив его параметром startScreenClass (```screens.open(Menu);``` -> ```screens.open(startScreenClass);```).

Сейчас мы можем загружать несколько приложений одновременно, но все они используют один и тот же объект Screens, поэтому ничего хорошего из этого пока не выходит. Пришло время убрать все синглтоны. Для начала удалим отовсюду подобный код:

```haxe
    private static var instance:Xxx;
    public static function getInstance():Xxx
    {
        if (instance == null)
        {
            instance = new Xxx();
        }
        return instance;
    }
    public function new()
    {
        if (instance != null)
        {
            throw new Exception("Singleton class can have only one instance!");
        }
        instance = this;
    }
```

Сделаем хранилище синглтонов в IoC. Синглтон — это единственный объект своего типа. Область, в которой объект является единственным, теперь будет ограничиваться не всем приложением, а только применением каждого конкретного экземпляра IoC. Таким образом, IoC является контекстом приложения. А так как IoC теперь тоже не синглтон и может иметь несколько экземпляров, то, получается, и контекстов у нас может быть несколько.

```haxe
class IoC
{
    //...
    // State
    private var singletonByTypeName:Map<String, Dynamic> = new Map();

    //...
    public function setSingleton<T>(type:Class<T>, instance:T):Void
    {
        if (type == null || instance == null)
        {
            return;
        }
        var typeName = Type.getClassName(type);
        var current = singletonByTypeName[typeName];
        if (current != null && current != instance)
        {
            throw new Exception('Singleton class can have only one instance!' +
                ' current: $current new: $instance');
        }
        singletonByTypeName[typeName] = instance;
    }
    public function getSingleton<T>(type:Class<T>):T
    {
        if (type == null)
        {
            return null;
        }
        var typeName = Type.getClassName(type);
        // Get
        var instance = singletonByTypeName[typeName];
        if (instance == null)
        {
            // Create
            instance = create(type);
            // Save by base type
            singletonByTypeName[typeName] = instance;
            // Save also by current type
            var currentType = Type.getClass(instance);
            var currentTypeName = Type.getClassName(currentType);
            singletonByTypeName[currentTypeName] = instance;
        }
        return cast instance;
    }
}
```

Так как больше нет статических методов getInstance(), то ссылку на IoC объект может получить только извне. Точнее, из того, класса, который его создал. А так как мы условились создавать все объекты через ```IoC.create()```, то разумнее будет тут же и устанавливать ссылку на ioc: ```Reflect.setProperty(result, "ioc", this);```. Так контекст приложения (ioc) распространяется по всему приложению, по всей иерархии компонентов, во все менеджеры.

Так как любой объект получает ссылки на другие объекты, без которых он не может работать, то можно сказать, что установление ioc фактически оживляет объект, а обнуление ioc его, соответственно, убивает. Так свойство ioc определяет жизненный цикл всякого объекта, в котором находится. Для компонента наличие ioc даже более важно, чем наличие skin, потому что когда устанавливается skin, дочерние компоненты чаще всего уже должны быть готовы, а они создаются через ioc.

Раз свойство ioc определяет жизненный цикл объекта, то сделаем его через сеттер set_ioc(). А сеттер реализуем как шаблонный метод, где явно пропишем все этапы жизненного цикла класса. При обнулении ioc (ioc=null) будет вызываться метод dispose(), а при установке ненулевого значения — init(). При замене ioc другим значением выполнятся оба шага.

Поскольку ioc нужен и компонентам и менеджерам, то воизбежание дублирования кода вынесем его в класс Base, от которого и те и другие и будут наследоваться:

```haxe
class Base
{
    // State
    private var ioc(default, set):IoC;
    private function set_ioc(value:IoC):IoC
    {
        if (ioc != value)
        {
            if (ioc != null)
            {
                // (To prevent calling set_ioc() again on ioc=null in dispose())
                ioc = null;
                // Dispose previous state
                dispose();
            }
            // Set
            ioc = value;
            if (ioc != null)
            {
                // Initialize
                init();
            }
        }
        return value;
    }
    // Override to change defaults and other settings which should be set only once
    public function new()
    {
    }
    // Override for initialization (create/get instances using IoC)
    private function init():Void
    {
    }
    // Override to revert changes of init and clear up the memory
    public function dispose():Void
    {
        ioc = null;
    }
}
class IoC extends Base
{
    //...
    public function new()
    {
        super();
        ioc = this;
    }
    override public function dispose():Void
    {
        for (instance in singletonByTypeName)
        {
            var base = Std.downcast(instance, IBase);
            if (base != null && base != this)
            {
                base.dispose();
            }
        }
        super.dispose();
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
        if (Reflect.hasField(result, "ioc"))
        {
            Reflect.setProperty(result, "ioc", this);
        }
        applyConfig(result, typeName, realType);
        return result;
    }
}
```

Вся инициализация объекта помещается в одном месте — в методе ```init()```. Он всегда вызывается сразу после того, как значение ```ioc``` задано. Тут устанавливаются ссылки на все глобальные объекты приложения (```ioc.getSingleton()```), создаются все заранее известные компоненты (т.е. такие, которые не зависят от скина) и другие объекты (```ioc.create()```).

Загрузчик может как увеличивать количество приложений, так и уменьшать их. Поэтому приложение должно уметь полностью уничтожаться, высвобождая все использованные ресурсы (память, файлы, соединения с сервером). Поэтому мы должны уметь уничтожать не только компоненты, но и менеджеры и другие объекты. Уничтожением объекта занимается метод ```dispose()```. Так он и попал в ```Base```.

В ```dispose()``` объект освобождается от всех внешних связей, установленных в ```init()```, чтобы сборщик мусора мог его спокойно удалить. Другими словами, ```init()``` и ```dispose()``` являются такими же парными и взаимообратимыми методами, как и ```assignSkin()``` и ```unassignSkin()```.

Уничтожить компонент можно двумя способами: вызвав dispose() или присвоив ioc=null. Оба способа равнозначны, потому что в первом случае присваивается ioc=null, а во втором — вызывается dispose(). Так, например, можно сменить ioc на другой, и тогда все внутренности будут уничтожены (dispose()) и пересозданы заново (init()). Это просто необходимо сделать, так как другой ioc может иметь совершенно другую конфигурацию типов и параметров объектов.

Наследуем же все основные классы фреймворка, которые будут использовать ```ioc```, от класса ```Base```:

```haxe
class Application extends Sprite
{
    //...
    private function init():Void
    {
        ioc = new IoC(); // Changed here
        // First of all set up IoC (register all class substitution, change defaultAssetName)
        configureApp();
    }
    //...
}
class GameApplication extends Application
{
    //...
    override private function init():Void
    {
        super.init();
        ioc.load();
        var audio = ioc.getSingleton(AudioManager); // Changed here
        var lang = ioc.getSingleton(LangManager); // Changed here
        audio.load();
        lang.load();
        audio.loadPrevious();
        lang.loadPrevious();
        screens = ioc.getSingleton(Screens); // Changed here
        screens.skin = this;
    }
    //...
}
class Component extends Base
{
    //...
    override public function dispose():Void
    {
        if (parent != null)
        {
            parent.removeChild(this);
        }
        skin = null;
        // Now we can dispose all children as they will be created again in init(),
        // so uncomment the following code
        for (child in children.copy())
        {
            child.dispose();
        }
        super.dispose();
    }
}
class ResourceManager extends Base
{
    //...
    override private function init():Void
    {
        super.init();
        // Throws exception if more than 1 instance
        ioc.setSingleton(ResourceManager, this);
    }
}
class AudioManager extends Base
{
    //...
    override private function init():Void
    {
        super.init();
        // Throws exception if more than 1 instance
        ioc.setSingleton(AudioManager, this);
        resourceManager = ioc.getSingleton(ResourceManager);
    }
    override public function dispose():Void
    {
        toggleSoundSignal.dispose();
        toggleMusicSignal.dispose();
        soundVolumeChangeSignal.dispose();
        musicVolumeChangeSignal.dispose();
        stopMusic();
        stopAllSounds();
        resourceManager = null;
        super.dispose();
    }
}
class LangManager extends Base
{
    //...
    override private function init():Void
    {
        super.init();
        // Throws exception if more than 1 instance
        ioc.setSingleton(LangManager, this);
        resourceManager = ioc.getSingleton(ResourceManager);
    }
    override public function dispose():Void
    {
        currentLangChangeSignal.dispose();
        resourceManager = null;
        super.dispose();
    }
}
```

Далее, нужно внести правки в производные от них классы. Заметим, что так как все дочерние компоненты (добавленные через ```addChild()```) удаляются автоматически (в ```Component.dispose()```), то переопределять ```dispose()``` в этих классах не нужно.

```haxe
class Button extends Component
{
    // State
    private var audio:AudioManager;
    //...
    override private function init():Void
    {
        super.init();
        audio = ioc.getSingleton(AudioManager);
        captionLabel = createComponent(Label);
        captionLabel.skinPath = captionLabelPath;
        addChild(captionLabel);
    }
    override public function dispose():Void
    {
        audio = null;
        // (captionLabel will be disposed automatically in super)
        super.dispose();
    }
    //...
    private function skin_clickHandler(event:MouseEvent):Void
    {
        if (!isEnabled)
        {
            return;
        }
        // was: AudioManager.getInstance().playSound(soundClick);
        audio.playSound(soundClick);
        //...
    }
}
class Label extends Component
{
    // State
    private var lang:LangManager; // was: = LangManager.getInstance();
    //...
    override private function init():Void
    {
        super.init();
        lang = ioc.getSingleton(LangManager);
    }
    override public function dispose():Void
    {
        audio = null;
        lang.dispose();
    }
    //...
}
class Screens extends Component
{
    //...
    override private function init():Void
    {
        super.init();
        resizer = createComponent(StageResizer);
        addChild(resizer);
    }
    //...
}
class Menu extends Component
{
    //...
    public function new()
    {
        super();
        // Default
        assetName = "dresser:AssetMenuScreen";
    }
    override private function init():Void
    {
        super.init();
        gameButton = createComponent(gameButtonType);
        //...
        addChild(gameButton);
        settingsPanel = createComponent(settingsPanelType);
        //...
        addChild(settingsPanel);
    }
    //...
}
class SettingsPanel extends Component
{
    //...
    // was in constructor
    override private function init():Void
    {
        super.init();
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
class LangPanel extends Component
{
    // State
    private var lang:LangManager; // was: = LangManager.getInstance();
    //...
    override private function init():Void
    {
        super.init();
        lang = ioc.getSingleton(LangManager);
    }
    override public function dispose():Void
    {
        lang = null;
        super.dispose();
    }
    //...
}
class SoundToggleButton extends CheckBox
{
    // State
    private var audio:AudioManager; // was: = AudioManager.getInstance();
    //...
    override private function init():Void
    {
        super.init();
        audio = ioc.getSingleton(AudioManager);
    }
    override public function dispose():Void
    {
        audio = null;
        super.dispose();
    }
    //...
}
class Dresser extends Component
{
    //...
    private var closeButton:Button;
    override private function init():Void
    {
        super.init();
        closeButton = createComponent(Button);
        closeButton.skinPath = "closeButton";
        closeButton.clickSignal.add(closeButton_clickSignalHandler);
        addChild(closeButton);
    }
    //...
}
```

Вот, наконец, компоненты приобрели, фактически, свой финальный вид, и мы можем перейти дальше — к написанию моделей и контроллеров. С этого момента мы от "разработки фреймворка" переключаемся на "разработку с помощью фреймворка".

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/h_loader/client_haxe/src/)

[< Назад](01_client_13.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](01_client_15.md)
