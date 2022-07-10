# Эволюция игрового фреймворка. Клиент 6. Масштабирование

Добавим последний штрих к скринам. Сейчас они добавляются на экран в том же размере, в каком они созданы в .fla. Если размеры приложения совпадают с размерами скринов и мы не будет их менять после запуска игры, то все хорошо. Но так бывает редко. Разрешения экранов на разных устройствах разные, да и пользователь может сам иногда ресайзить окно с игрой. Поэтому важно подстраивать размер всякого нового скрина под текущее состояние сцены (stage). Создадим эту функциональность сразу в отдельном компоненте StageResizer:

```haxe
class StageResizer extends Component
{
    // Settings
    // State
    private var stage(default, set):Stage;
    private function set_stage(value:Stage):Stage
    {
        if (stage == value)
        {
            return stage;
        }
        if (stage != null)
        {
            stage.removeEventListener(Event.RESIZE, stage_resizeHandler);
        }
        stage = value;
        if (stage != null)
        {
            resize();
            stage.addEventListener(Event.RESIZE, stage_resizeHandler);
        }
        return stage;
    }

    override private function assignSkin():Void
    {
        super.assignSkin();
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
        super.unassignSkin();
    }
    private function resize():Void
    {
        // Fit min
        skin.width = stage.stageWidth;
        skin.scaleY = skin.scaleX;
        if (skin.height > stage.stageHeight)
        {
            skin.height = stage.stageHeight;
            skin.scaleX = skin.scaleY;
        }
        // Align center, considering skin's center is in top left corner
        skin.x = Math.round((stage.stageWidth - skin.width) / 2);
        skin.y = Math.round((stage.stageHeight - skin.height) / 2);
    }
    private function skin_addedToStageHandler(event:Event):Void
    {
        stage = skin.stage;
    }
    private function skin_removedFromStageHandler(event:Event):Void
    {
        stage = skin.stage;// null
    }
    private function stage_resizeHandler(event:Event):Void
    {
        resize();
    }
}
```

Существует множество стратегий подгонки размеров: с сохранением пропорций (scaling) и без (stretching), вписывание объекта в данные границы или максимальное заполнение им всего экрана, с выравниваним его по вертикали и горизонтали или нет. Сейчас мы реализовали самый подходящий в данном случае: вписывание объекта по меньшей стороне, чтобы не было ничего за пределами видимости, с центрированием по другой оси. Чтобы изменить способ масштабирования, можно переопределить метод ```resize()``` в подклассе. Другой способ — реализовать все стратегии в одном классе и выбирать их настройками: resizeMode (со значениями "fitMin", "fitMax", "stretch"), alignH ("left", "center", "right"), alignV ("top", "center", "bottom").

Чтобы внедрить наше решение в практику, достаточно добавить в класс Screens всего одну строку — ```addChild(new StageResizer());```. Но мы разобьем ее на три:

```haxe
class Screens extends Component
{
    private var currentScreen:Component;
    private var resizer:StageResizer;

    public function new()
    {
        super();
        resizer = new StageResizer();
        addChild(resizer);
    }
    public function open(screenClass:Class<Dynamic>, ?assetName:String):Void
    {
        // Dispose current
        if (currentScreen != null)
        {
            currentScreen.dispose();
        }
        // Create new
        currentScreen = Type.createInstance(screenClass, []);
        // (All properties should be set up before addChild() called and skin created)
        currentScreen.assetName = assetName;
        addChild(currentScreen); // Skin will be created here
        // Resize
        resizer.skin = currentScreen.skin;
    }
}
```

Класс StageResizer наглядно демонстрирует всю простоту и мощь компонентов. Мы можем создать функциональность в чистом виде — которая будет независима от всех внешних классов. А чтобы ее использовать, в любом месте приложения достаточно добавить всеге несколько строк.


[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/blob/main/d_managers/client_haxe/src/v1/)


[< Назад](01_client_05.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](01_client_07.md)
