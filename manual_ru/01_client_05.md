# Эволюция игрового фреймворка. Клиент 5. Скрины

Теперь, когда мы [закончили](01_client_04.md) с построением иерархии компонентов и у нас есть не только свойство `children`, но и `parent`, мы можем создать финальное и притом универсальное решение для установки скинов. Напомним, что скины можно определять двумя путями:
1. Создавать новый мувиклип по assetName.
2. Брать внутренние объекты ранее созданных мувиклипов по skinPath.

На данный момент оба способа реализованы в классе `Component` следующим образом:

```haxe
class Component
{
    private var assetName:String;
    private var skinPath:String = "";
    //...
    public function new(?skin:DisplayObject, ?assetName:String)
    {
        this.skin = skin;
        if (assetName != null) // To do not overwrite default value with null
        {
            this.assetName = assetName;
        }
        createSkin();
    }
    private function createSkin():Void
    {
        if (assetName == null)
        {
            return;
        }
        var mc = Assets.getMovieClip(assetName);
        if (mc != null && container != null)
        {
            // Add to current temporary skin
            container.addChild(mc);
            // Set real component's skin
            skin = mc;
        }
    }
    private function assignSkin():Void
    {
        // Set skin for children using skinPath or assetName
        for (child in children.copy())
        {
            if (child.assetName != null)
            {
                var mc = Assets.getMovieClip(child.assetName);
                container.addChild(mc);
                child.skin = mc;
            }
            else
            {
                child.skin = resolveSkinPath(child.skinPath);
            }
        }
    }
    //...
}
```

По традиции, в этом коде есть *две* проблемы. Первая состоит в том, что skin устанавливается дважды: в конструкторе и `createSkin()`. А значит и `assignSkin()` с `unassignSkin()` будут вызваны по два раза. Вторая проблема — это дублирование кода. Содержание метода `createSkin()` уже включено в `assignSkin()`.

На данном этапе решение этих вопросов пока что не прослеживается, так как мы реализовали только половину обычного приложения и у нас еще попросту недостаточно материала для принятия взвешенного решения. Что бы мы ни придумали сейчас, скорее всего это придется переделывать потом — после того, как мы сделаем еще хотя бы один экран. Поэтому приступим к более насущной задаче — переключению экранов. А остальные проблемы, может быть, и вовсе решатся сами собой.

## Создание экрана для меню

Сейчас Main сразу создает "экранный" компонент Dresser, так как он у нас пока единственный. Но в реальных играх как минимум существует еще экран меню (Menu) или лобби (Lobby). Создадим в дополнение к Dresser простейший класс Menu, в котором будет только одна кнопка для перехода в игру:

```haxe
class Main extends Sprite
{
    public function new()
    {
        super();
        new Menu(this);
    }
}
class Menu extends Component
{
    private var gameButton:Button;
    public function new(?skin:DisplayObject, ?assetName:String)
    {
        // Default
        assetName = assetName != null ? assetName : "dresser:AssetMenuScreen";
        gameButton = new Button();
        gameButton.skinPath = "gameButton";
        gameButton.clickHandler = gameButton_clickHandler;
        addChild(gameButton);
        // If assetName defined, then current given skin would be temporary for this component
        super(skin, assetName);
    }
    private function gameButton_clickHandler(target:Button):Void
    {
        // Switch to Dresser
        new Dresser(skin.parent);
        // Remove current
        skin.parent.removeChild(skin);
        skin = null;
    }
}
class Dresser extends Component
{
    public function new(?skin:DisplayObject, ?assetName:String)
    {
        // Default
        assetName = assetName != null ? assetName : "dresser:AssetDresserScreen";
        //...
        // If assetName defined, then current given skin would be temporary for this component
        super(skin, assetName);
    }
    //...
    private function closeButton_clickHandler(target:Button):Void
    {
        // Switch to Menu
        new Menu(skin.parent);
        // Remove current
        skin.parent.removeChild(skin);
        skin = null;
    }
}
```

Посмотрим, что у нас получилось. После запуска приложения Main создает класс Menu и передает в него ссылку на себя. Menu создает согласно значению в assetName новый мувиклип и добавляет его в текущий skin, то есть в Main. После клика на единственную кнопку (gameButton) создается класс Dresser, в который передается ссылка на Main (skin.parent), и процесс с созданием нового мувиклипа повторяется. Аналогично происходит при клике на кнопку выхода из игры (closeButton). И хотя все ссылки на скины обнуляются и они будут подобраны сборщиком мусора и удалены из памяти, и, казалось бы, нас такое решение могло бы с технической точки зрения удовлетворить, но оно все же не удовлетворяет.

И дело даже не в дублировании кода. Его можно было бы устранить простым наследованием обоих экранов от общего предка Screen. Например, так:

```haxe
class Screen extends Component
{
    private function open(screenClass:Class<Dynamic>, ?assetName:String):Void
    {
        // Switch to new screen
        var screen = Type.createInstance(screenClass, [skin.parent, assetName]);
        // Remove current
        skin.parent.removeChild(skin);
        skin = null;
    }
}
class Menu extends Screen
{
    //...
    private function gameButton_clickHandler(target:Button):Void
    {
        open(Dresser);
    }
}
class Dresser extends Screen
{
    //...
    private function closeButton_clickHandler(target:Button):Void
    {
        open(Menu);
    }
}
```

Плохо тут то, что у Main нет своего компонента и к нему приходится обращаться косвенно через `skin.parent`. Если мы создадим такой компонент, то он будет корневым компонентом для всего приложения и его можно было бы назвать Application. Но так как он пока выполняет ограниченную роль контейнера для экранов, то назовем его пока скромнее — Screens.

## Контейнер экранов

Логичнее будет в Screens перенести и метод `open()`. Так мы к тому же избавимся от необходимости для экранов наследоваться от класса Screen (который нам больше не нужен). Тогда в качестве скринов могут использоваться любые компоненты.

```haxe
class Main extends Sprite
{
    public function new()
    {
        super();
        var screens = new Screens(this);
        screens.open(Menu);
    }
}
class Screens extends Component
{
    private var currentScreen:Component;
    public function open(screenClass:Class<Dynamic>, ?assetName:String):Void
    {
        // Dispose current
        if (currentScreen != null)
        {
            currentScreen.dispose();
        }
        // Create new
        currentScreen = Type.createInstance(screenClass, [skin, assetName]);
        addChild(currentScreen);
    }
}
class Menu extends Component
{
    //...
    private function gameButton_clickHandler(target:Button):Void
    {
        var screens:Screens = Std.downcast(parent, Screens);
        if (screens != null)
        {
            screens.open(Dresser);
        }
    }
}
class Dresser extends Component
{
    //...
    private function closeButton_clickHandler(target:Button):Void
    {
        var screens:Screens = Std.downcast(parent, Screens);
        if (screens != null)
        {
            screens.open(Menu);
        }
    }
}
```

Вот теперь, когда мы реализовали возможность перехода между несколькими экранами, мы можем вернуться к решению проблем, поставленных в начале данного раздела. А именно выработать оптимальный способ создания скинов.

## Улучшение механизма создания скинов

Нам желательно, чтобы скины создавались автоматически в самом классе Component. И чтобы их создавал не родитель, а сам компонент, пользуясь ссылкой на своего родителя. Это будет самое универсальное решение. Ссылка на родителя гарантированно есть в `addChild()`, поэтому все скины можно устанавливать в нем. Но еще лучше сделать само свойство `parent` сеттером и перенести эту функцию туда:

```haxe
class Component
{
    //...
    public var parent(default, set):Component;
    private function set_parent(value:Component):Component
    {
        if (parent != value)
        {
            // Remove skin created by assetName
            if (assetName != null && skin != null && skin.parent != null)
            {
                skin.parent.removeChild(skin);
                skin = null;
            }
            // Set
            parent = value;
            // Create skin by assetName
            if (assetName != null && parent != null && parent.skin != null)
            {
                // (All component properties should be set by now)
                createSkin();
            }
        }
        return value;
    }
    private function createSkin():Void
    {
        if (assetName == null)
        {
            return;
        }
        var mc = Assets.getMovieClip(assetName);
        if (mc != null && parent != null && parent.container != null)
        {
            // Add to parent's skin
            parent.container.addChild(mc);
        }
        // Set real component's skin
        skin = mc;
    }
    //...
}
```

Раз что-то было создано, то оно должно быть и уничтожено. Таков закон. Потому что на создание любого объекта выделяются ресурсы (память), а когда объект больше не используется, эти ресурсы должны быть освобождены. Иначе они рано или поздно закончатся. Приложение начнет тормозить, а потом и вовсе зависнет. При этом желательно, чтобы удаление объекта происходило там же, где и его создание. Как минимум в том же классе. Иначе говоря, создатель объекта несет ответственность за его уничтожение. Этот принцип можно условно назвать **принципом Тараса Бульбы**. Вот почему перед изменением `parent` мы должны автоматически удалить скин, если он был создан с помощью assetName.

Но так как свойство `skin` остается публичным, и существует техническая возможность изменения skin'а без изменения parent'а компонента, то нужно предусмотреть возможность автоматического удаления скина, созданного по assetName, со сцены и для такого варианта. Поэтому `skin.parent.removeChild(skin);` придется перенести в `unassignSkin()`.

```haxe
class Component
{
    //...
    public var parent(default, set):Component;
    private function set_parent(value:Component):Component
    {
        if (parent != value)
        {
            // Remove skin created by assetName
            if (assetName != null && skin != null && skin.parent != null)
            {
                skin = null;
            }
            // Set
            parent = value;
            // Create skin by assetName
            if (assetName != null && parent != null && parent.skin != null)
            {
                // (All component properties should be set by now)
                createSkin();
            }
        }
        return value;
    }
    private function unassignSkin():Void
    {
        //...
        // Remove skin created by assetName
        if (assetName != null && skin.parent != null)
        {
            skin.parent.removeChild(skin);
        }
    }
    //...
}
```

Вынесение создания скина из конструктора позволяет нам произвести настройку свойств компонента перед тем, как скин будет задан и вызовется `assignSkin()`, использующий эти свойства. Поэтому настройка всегда производится между созданием экземпляра компонента и добавлением его к родителю (`addChild()`). Тогда и skin, и assetName можно убрать из параметров конструктора Component:

```haxe
class Component
{
    //...
    public function new()
    {
    }
    //...
}
class Screens extends Component
{
    // State
    private var currentScreen:Component;

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
    }
}
```

Первая проблема решена: при использовании `assetName` свойство skin устанавливается только один раз, и двойного вызова `assignSkin()` и `unassignSkin()` не происходит. Теперь посмотрим еще раз на применение `skinPath`. Раньше за присвоение скинов своим дочерним элементам отвечал родительский компонент, так как у нас было только свойство `children`.

```haxe
class Component
{
    //...
    private function createSkin():Void
    {
        if (assetName == null)
        {
            return;
        }
        var mc = Assets.getMovieClip(assetName);
        if (mc != null && parent != null && parent.container != null)
        {
            // Add to parent's skin
            parent.container.addChild(mc);
        }
        // Set real component's skin
        skin = mc;
    }
    private function assignSkin():Void
    {
        // Set skin for children using skinPath or assetName
        for (child in children.copy())
        {
            if (child.assetName != null)
            {
                // Was:
                //var mc = Assets.getMovieClip(child.assetName);
                //container.addChild(mc);
                //child.skin = mc;
                // New:
                child.createSkin();
            }
            else
            {
                child.skin = resolveSkinPath(child.skinPath);
            }
        }
    }
    //...
}
```

Теперь, когда есть еще и `parent`, у нас появляется возможность пересмотреть старое решение: не получится ли объединить код из `assignSkin()` с `createSkin()`. Что если объединить получение скина по assetName и `skinPath` в одном методе `createSkin()`, который будет более уместно теперь переименовать в `setSkin()`.

Тогда у нас получится, что родитель не устанавливает скин своим "отпрыскам", а как бы просит их самих установить себе скины, беря его скин как базовый контейнер. Если у дочернего компонента определен assetName, то в этот контейнер будет помещен вновь созданный мувиклип; если определен skinPath, то контейнер будет использован как источник для поиска подходящего скина:

```haxe
class Component
{
    //...
    public var parent(default, set):Component;
    private function set_parent(value:Component):Component
    {
        if (parent != value)
        {
            // Remove skin created by assetName
            if (assetName != null && skin != null && skin.parent != null)
            {
                skin = null;
            }
            // Set
            parent = value;
            // Create skin by assetName
            if (assetName != null && parent != null && parent.skin != null)
            {
                // (All component properties should be set by now)
                setSkin();
            }
        }
        return value;
    }

    private function assignSkin():Void
    {
        // Set skin for children using skinPath or assetName
        for (child in children.copy())
        {
            child.setSkin();
        }
    }
    private function unassignSkin():Void
    {
        //...
        // Remove skin created by assetName
        if (assetName != null && skin.parent != null)
        {
            skin.parent.removeChild(skin);
        }
    }
    private function setSkin():Void
    {
        if (skin != null)
        {
            // Already set
            return;
        }
        if (assetName != null)
        {
            // Create by assetName
            var mc = Assets.getMovieClip(assetName);
            if (mc != null && parent != null && parent.container != null)
            {
                parent.container.addChild(mc);
            }
            skin = mc;
        }
        else if (skinPath != null)
        {
            // Get by skinPath
            skin = resolveSkinPath(skinPath, parent.container);
        }
    }
    //...
}
```

Если `skinPath == ""`, то у данного дочернего компонента будет такой же skin, как и у родительского, а если `skinPath == null`, то не будет присвоено никакого скина. Нужно предусмотреть и такую возможность.

Свойства `assetName` и `skinPath`, как, собственно, и все прочие, должны быть заданы до вызова метода `addChild()`. Данная функция фактически завершает инициализацию компонента. После этого он полностью готов к работе.

Приведем полный текст класс Dresser, чтобы посмотреть, как в итоге изменилось использование класса Component:

```haxe
class Dresser extends Component
{
    // Settings
    public var itemPathPrefix = "item";
    public var prevButtonPathPrefix = "prevButton";
    public var nextButtonPathPrefix = "nextButton";
    // State
    private var items:Array<MovieClip>;
    private var prevButtonSkins:Array<MovieClip>;
    private var nextButtonSkins:Array<MovieClip>;

    public function new()
    {
        super();
        var closeButton = new Button();
        closeButton.skinPath = "closeButton";
        closeButton.clickHandler = closeButton_clickHandler;
        addChild(closeButton); // Skin will be set by super.assignSkin()
    }
    override private function assignSkin():Void
    {
        super.assignSkin();

        items = cast resolveSkinPathPrefix(itemPathPrefix);
        prevButtonSkins = cast resolveSkinPathPrefix(prevButtonPathPrefix);
        nextButtonSkins = cast resolveSkinPathPrefix(nextButtonPathPrefix);
        for (item in items)
        {
            item.stop();
            // Make items draggable
            var drag = new Drag();
            drag.skin = item; // Set skin directly
            addChild(drag);
        }
        for (prevButtonSkin in prevButtonSkins)
        {
            var prevButton = new Button();
            prevButton.skinPath = prevButtonSkin.name; // Set skinPath
            prevButton.clickHandler = prevButton_clickHandler;
            addChild(prevButton); // Skin will be set here
        }
        for (nextButtonSkin in nextButtonSkins)
        {
            var nextButton = new Button();
            nextButton.skin = nextButtonSkin; // Set skin directly
            nextButton.clickHandler = nextButton_clickHandler;
            addChild(nextButton); // Skin is already set and won't change
        }
    }
    override private function unassignSkin():Void
    {
        items = null;
        prevButtonSkins = null;
        nextButtonSkins = null;

        super.unassignSkin();
    }
    private function closeButton_clickHandler(target:Button):Void
    {
        var screens:Screens = Std.downcast(parent, Screens);
        if (screens != null)
        {
            screens.open(Menu);
        }
    }
    private function prevButton_clickHandler(target:Button):Void
    {
        var index = prevButtonSkins.indexOf(target.skin);
        var item:MovieClip = items[index];
        if (item != null)
        {
            item.gotoAndStop(item.currentFrame - 1);
        }
    }
    private function nextButton_clickHandler(target:Button):Void
    {
        var index = nextButtonSkins.indexOf(target.skin);
        var item:MovieClip = items[index];
        if (item != null)
        {
            item.gotoAndStop(item.currentFrame + 1);
        }
    }
}
```

Дочерний компонент может быть добавлен в конструкторе, когда скина еще нет и быть не может. А может — и в `assignSkin()`, когда скин есть гарантированно. В обоих случаях скин дочернего элемента будет установлен, т.к. метод `setSkin()` вызывается из двух мест: из `assignSkin()` для первого случая, и из `set_parent()` — для второго. Также для обоих случаев работает автоматическая очистка или полное удаление дочерних компонентов при обнулении родительского скина, поэтому метод `unassignSkin()` почти пустой.

Заметим еще, что когда мы устанавливаем напрямую скины, полученные с помощью `resolveSkinPathPrefix()`, нам в компоненте не известно, по какому пути (skinPath) он был получен. Это не очень-то важно, но при отладке бывает нелишним знать, что данный скин был получен оттуда-то и оттуда. Поэтому для последовательности и консистентности лучше, чтобы `resolveSkinPathPrefix()` возвращало не массив скинов, а массив путей к скинам, которые реально существуют.

```haxe
class Component
{
    //...
    private function resolveSkinPathPrefix(pathPrefix:String):Array<String>
    {
        var result = [];
        var i = 0;
        while (true)
        {
            var path = pathPrefix + i;
            var item = resolveSkinPath(path);
            if (item == null)
            {
                // No more children
                break;
            }
            // Another child is found
            result.push(path);
            i++;
        }
        return result;
    }
    //...
}
class Dresser extends Component
{
    // Settings
    public var itemPathPrefix = "item";
    public var prevButtonPathPrefix = "prevButton";
    public var nextButtonPathPrefix = "nextButton";
    // State
    private var items:Array<MovieClip>;
    private var prevButtons:Array<Button>;
    private var nextButtons:Array<Button>;

    public function new()
    {
        super();
        var closeButton = new Button();
        closeButton.skinPath = "closeButton";
        closeButton.clickHandler = closeButton_clickHandler;
        addChild(closeButton); // Skin will be set by super.assignSkin()
    }
    override private function assignSkin():Void
    {
        super.assignSkin();

        var itemPaths = cast resolveSkinPathPrefix(itemPathPrefix);
        items = [for (path in itemPaths) resolveSkinPath(path)];
        var prevButtonPaths = cast resolveSkinPathPrefix(prevButtonPathPrefix);
        var nextButtonPaths = cast resolveSkinPathPrefix(nextButtonPathPrefix);
        for (item in items)
        {
            item.stop();
            // Make items draggable
            var drag = new Drag();
            drag.skin = item; // Set skin directly
            addChild(drag);
        }
        prevButton = [];
        for (path in prevButtonPaths)
        {
            var prevButton = new Button();
            prevButton.skinPath = path;
            prevButton.clickHandler = prevButton_clickHandler;
            addChild(prevButton); // Skin will be set here
            prevButton.push(prevButton);
        }
        nextButton = [];
        for (path in nextButtonPaths)
        {
            var nextButton = new Button();
            nextButton.skinPath = path;
            nextButton.clickHandler = nextButton_clickHandler;
            addChild(nextButton); // Skin will be set here
            prevButton.push(nextButton);
        }
    }
    //...
    private function prevButton_clickHandler(target:Button):Void
    {
        var index = prevButtons.indexOf(target);
        var item:MovieClip = items[index];
        if (item != null)
        {
            item.gotoAndStop(item.currentFrame - 1);
        }
    }
    private function nextButton_clickHandler(target:Button):Void
    {
        var index = nextButtons.indexOf(target);
        var item:MovieClip = items[index];
        if (item != null)
        {
            item.gotoAndStop(item.currentFrame + 1);
        }
    }
}
```

Подытоживая значение подсистемы экранов, мы можем выделить главное, что она дает. А именно: разбиение всего приложения на модули и возможность разрабатывать модули отдельно друг от друга. Так, если мы создали меню и панель настроек для одной игры, то когда мы перейдем к новому проекту, нам не нужно делать повторно тот же функционал. Мы просто переносим готовый функционал из старого проекта, а в новом — сосредотачиваемся исключительно на новых фичах.

В рамках данной статьи мы довели класс Component практически до законченного вида. С этого момента, мы его будем только использовать, но не менять.

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/c_screens/client_haxe/src/)

[< Назад](01_client_04.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](01_client_06.md)
